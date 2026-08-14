class Constants {
  static const String inlineJsScript = r'''
                (function() {
                  function decodeEntities(text) {
                    if (!text) return "";
                    return text
                      .replace(/&quot;/g, '"')
                      .replace(/&amp;/g, '&')
                      .replace(/&#39;/g, "'")
                      .replace(/&apos;/g, "'")
                      .replace(/&lt;/g, '<')
                      .replace(/&gt;/g, '>')
                      .replace(/&#91;/g, '[')
                      .replace(/&#93;/g, ']');
                  }

                  function deepMerge(base, override) {
                    var merged = Object.assign({}, base);
                    for (var key in override) {
                      if (override.hasOwnProperty(key)) {
                        var overVal = override[key];
                        var baseVal = merged[key];
                        if (overVal && typeof overVal === 'object' && !Array.isArray(overVal) && baseVal && typeof baseVal === 'object' && !Array.isArray(baseVal)) {
                          merged[key] = deepMerge(baseVal, overVal);
                        } else if (Array.isArray(overVal) && Array.isArray(baseVal)) {
                          merged[key] = mergeLists(baseVal, overVal);
                        } else {
                          merged[key] = overVal;
                        }
                      }
                    }
                    return merged;
                  }

                  function mergeLists(baseList, overrideList) {
                    var result = [].concat(baseList);
                    for (var i = 0; i < overrideList.length; i++) {
                      var overItem = overrideList[i];
                      if (overItem && typeof overItem === 'object') {
                        var overId = overItem['@id'] || overItem['id'];
                        if (overId) {
                          var idx = result.findIndex(function(baseItem) {
                            if (baseItem && typeof baseItem === 'object') {
                              var baseId = baseItem['@id'] || baseItem['id'];
                              return baseId === overId;
                            }
                            return false;
                          });
                          if (idx !== -1) {
                            result[idx] = deepMerge(result[idx], overItem);
                          } else {
                            result.push(overItem);
                          }
                        } else {
                          result.push(overItem);
                        }
                      } else {
                        if (result.indexOf(overItem) === -1) {
                          result.push(overItem);
                        }
                      }
                    }
                    return result;
                  }

                  function resolveId(base, id) {
                    if (id.indexOf('http://') === 0 || id.indexOf('https://') === 0) {
                      return { url: id };
                    }
                    var baseParts = base.split('/');
                    var defaultBlogId = baseParts[0] || '';
                    var idParts = id.split('/');
                    if (idParts.length === 1) {
                      return { blogId: defaultBlogId, postId: idParts[0] };
                    } else if (idParts.length >= 2) {
                      return { blogId: idParts[0], postId: idParts[1] };
                    }
                    return { blogId: defaultBlogId, postId: '' };
                  }

                  async function fetchPostSchema(blogId, postId) {
                    var url = 'https://www.blogger.com/feeds/' + blogId + '/posts/default/' + postId + '?alt=json';
                    try {
                      var res = await fetch(url);
                      if (!res.ok) return null;
                      var data = await res.json();
                      var content = data.entry && data.entry.content ? data.entry.content.$t : '';
                      return extractJsonLd(content);
                    } catch(e) {
                      return null;
                    }
                  }

                  function extractJsonLd(content) {
                    if (!content) return null;
                    try {
                      var scriptMatch = content.match(/<script[^>]*type=["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/i);
                      var jsonStr = scriptMatch ? scriptMatch[1] : content;
                      jsonStr = decodeEntities(jsonStr).trim();
                      return JSON.parse(jsonStr);
                    } catch(e) {
                      return null;
                    }
                  }

                  async function resolveAndLoadSchema(schema, base) {
                    var resolved = Object.assign({}, schema);
                    await traverseAndResolve(resolved, base);
                    return resolved;
                  }

                  async function traverseAndResolve(node, base) {
                    if (node && typeof node === 'object') {
                      if (!Array.isArray(node)) {
                        var idVal = node['@id'] || node['id'];
                        if (idVal && typeof idVal === 'string') {
                          var resolvedId = resolveId(base, idVal);
                          var blogId = resolvedId.blogId;
                          var postId = resolvedId.postId;
                          var fullUrl = resolvedId.url;
                          var fetchedSchema = null;
                          if (blogId && postId) {
                            fetchedSchema = await fetchPostSchema(blogId, postId);
                          } else if (fullUrl) {
                            try {
                              var res = await fetch(fullUrl);
                              if (res.ok) {
                                var text = await res.text();
                                fetchedSchema = extractJsonLd(text);
                              }
                            } catch(e) {}
                          }
                          if (fetchedSchema) {
                            var nestedBase = (blogId && postId) ? (blogId + '/' + postId) : base;
                            fetchedSchema = await resolveAndLoadSchema(fetchedSchema, nestedBase);
                            var merged = deepMerge(fetchedSchema, node);
                            for (var key in node) {
                              if (node.hasOwnProperty(key)) delete node[key];
                            }
                            Object.assign(node, merged);
                            return;
                          }
                        }
                        for (var key in node) {
                          if (node.hasOwnProperty(key)) {
                            var val = node[key];
                            if (val && typeof val === 'object') {
                              await traverseAndResolve(val, base);
                            }
                          }
                        }
                      } else {
                        for (var i = 0; i < node.length; i++) {
                          var item = node[i];
                          if (item && typeof item === 'object') {
                            await traverseAndResolve(item, base);
                          }
                        }
                      }
                    }
                  }

                  function toGraphDocument(schemas) {
                    var inputList = Array.isArray(schemas) ? schemas : [schemas];
                    var contextUrls = new Set();
                    var combinedContextMap = {};
                    var entityMap = new Map();
                    var standaloneNodes = [];

                    function mergeContextValue(contextVal) {
                      if (!contextVal) return;
                      if (typeof contextVal === 'string') {
                        contextUrls.add(contextVal);
                      } else if (Array.isArray(contextVal)) {
                        for (var i = 0; i < contextVal.length; i++) {
                          mergeContextValue(contextVal[i]);
                        }
                      } else if (typeof contextVal === 'object' && contextVal !== null) {
                        for (var key in contextVal) {
                          if (contextVal.hasOwnProperty(key)) {
                            var v = contextVal[key];
                            if (v === null || v === undefined) continue;
                            if (typeof v === 'object' && !Array.isArray(v)) {
                              var existing = combinedContextMap[key];
                              if (existing && typeof existing === 'object' && !Array.isArray(existing)) {
                                combinedContextMap[key] = deepMerge(existing, v);
                              } else {
                                combinedContextMap[key] = deepMerge({}, v);
                              }
                            } else {
                              combinedContextMap[key] = v;
                            }
                          }
                        }
                      }
                    }

                    function extractAndStripContext(node) {
                      if (!node || typeof node !== 'object') return node;
                      if (Array.isArray(node)) {
                        return node.map(extractAndStripContext);
                      }
                      if (node.hasOwnProperty('@context') && node['@context']) {
                        mergeContextValue(node['@context']);
                      }
                      var cleaned = {};
                      for (var key in node) {
                        if (node.hasOwnProperty(key)) {
                          if (key === '@context') continue;
                          cleaned[key] = extractAndStripContext(node[key]);
                        }
                      }
                      return cleaned;
                    }

                    function registerEntity(node) {
                      var id = node['@id'] || node['id'];
                      if (id && typeof id === 'string') {
                        if (entityMap.has(id)) {
                          var existing = entityMap.get(id);
                          entityMap.set(id, deepMerge(existing, node));
                        } else {
                          entityMap.set(id, node);
                        }
                      } else {
                        standaloneNodes.push(node);
                      }
                    }

                    for (var i = 0; i < inputList.length; i++) {
                      var schema = inputList[i];
                      var cleanedSchema = extractAndStripContext(schema);
                      if (cleanedSchema && Array.isArray(cleanedSchema['@graph'])) {
                        for (var j = 0; j < cleanedSchema['@graph'].length; j++) {
                          registerEntity(cleanedSchema['@graph'][j]);
                        }
                      } else if (cleanedSchema) {
                        registerEntity(cleanedSchema);
                      }
                    }

                    // Build unified context
                    var finalContext = 'https://schema.org';
                    var isSchemaOrg = false;
                    contextUrls.forEach(function(u) {
                      if (u.indexOf('schema.org') !== -1) isSchemaOrg = true;
                    });
                    for (var k in combinedContextMap) {
                      if (combinedContextMap.hasOwnProperty(k)) {
                        if (k === '@vocab' || k === 'schema') isSchemaOrg = true;
                      }
                    }

                    var customUrls = [];
                    contextUrls.forEach(function(u) {
                      if (u.indexOf('schema.org') === -1) customUrls.push(u);
                    });

                    var customMap = {};
                    for (var k in combinedContextMap) {
                      if (combinedContextMap.hasOwnProperty(k)) {
                        if (k === '@vocab' && combinedContextMap[k].indexOf('schema.org') !== -1) continue;
                        if (k === 'schema' && combinedContextMap[k].indexOf('schema.org') !== -1) continue;
                        customMap[k] = combinedContextMap[k];
                      }
                    }

                    var hasCustom = customUrls.length > 0 || Object.keys(customMap).length > 0;
                    if (!hasCustom) {
                      finalContext = 'https://schema.org';
                    } else {
                      var unified = {};
                      if (isSchemaOrg) {
                        unified['@vocab'] = 'https://schema.org/';
                        unified['schema'] = 'https://schema.org/';
                      }
                      for (var k in customMap) {
                        if (customMap.hasOwnProperty(k)) {
                          unified[k] = customMap[k];
                        }
                      }
                      if (customUrls.length > 0) {
                        var resList = [].concat(customUrls);
                        if (Object.keys(unified).length > 0) resList.push(unified);
                        finalContext = resList;
                      } else {
                        finalContext = unified;
                      }
                    }

                    var entities = [];
                    entityMap.forEach(function(val) {
                      entities.push(val);
                    });

                    return {
                      '@context': finalContext,
                      '@graph': entities.concat(standaloneNodes)
                    };
                  }

                  // Entry point
                  async function init() {
                    var localJsonLdEl = document.getElementById('raw-jsonld');
                    if (!localJsonLdEl) return;
                    var base = localJsonLdEl.getAttribute('data-base') || '';
                    var rawContent = localJsonLdEl.textContent || '';
                    var localSchema = extractJsonLd(rawContent);
                    if (!localSchema) return;

                    // Resolve references and fetch dynamically from Blogger at runtime in the browser!
                    var fullyMergedSchema = await resolveAndLoadSchema(localSchema, base);

                    // Compile into a clean, flat unified @graph document structure at runtime!
                    var unifiedGraphDocument = toGraphDocument(fullyMergedSchema);

                    // Update AMP State dynamically with clean @graph representation!
                    AMP.setState({ productState: unifiedGraphDocument });
                  }

                  init();
                })();
              ''';
}
