import 'package:blogger_theme/blogger_theme.dart';

class ThemeBuilder {
  static BloggerTheme buildTheme() {
    return BloggerTheme(
      attributes: {
        'b:responsive': 'true',
        'b:defaultwidgetversion': '2',
        'b:layoutsversion': '3',
        'b:css': 'false', // Disables default Blogger CSS globally
        'xmlns': 'http://www.w3.org/1999/xhtml',
        'xmlns:b': 'http://www.google.com/2005/gml/b',
        'xmlns:data': 'http://www.google.com/2005/gml/data',
        'xmlns:expr': 'http://www.google.com/2005/gml/expr',
      },
      children: [
        BAttr(name: 'xmlns', value: ''),
        BAttr(name: 'xmlns:b', value: ''),
        BAttr(name: 'xmlns:expr', value: ''),
        BAttr(name: 'xmlns:data', value: ''),
        BAttr(cond: 'data:blog.isMobileRequest', name: 'amp', value: 'amp'),
      ],
      head: [
        AmpCharset(),
        AmpViewport(),
        Link(
          attributes: {
            'rel': 'canonical',
            'expr:href': 'data:blog.canonicalUrl',
          },
        ),
        Title(children: [
          const BData(value: 'blog.pageTitle'),
        ]),

        // Required AMP Extension Scripts
        AmpRuntimeScript(),
        AmpExtensionScript(extension: 'amp-bind'),
        AmpExtensionScript(extension: 'amp-list'),
        AmpExtensionScript(extension: 'amp-form'),
        AmpExtensionScript(extension: 'amp-mustache', version: '0.2', type: 'custom-template'),
        AmpExtensionScript(extension: 'amp-carousel'),
        AmpExtensionScript(extension: 'amp-lightbox'),
        AmpExtensionScript(extension: 'amp-sidebar'),
        AmpExtensionScript(extension: 'amp-selector'),
        AmpExtensionScript(extension: 'amp-autocomplete'),
        AmpExtensionScript(extension: 'amp-script'),

        // AMP Boilerplate styles
        const AmpBoilerplate(),

        // Dynamic Blogger Theme variables for the Theme Designer UI
        // Disables default b:skin CSS output while preserving custom color variables for AMP compliance.
        BIf(
          cond: false.toString(),
          children: [
            const BSkin(
              "",
              variables: [
                BVariable(
                  name: "primary_color",
                  description: "Primary Theme Color",
                  type: "color",
                  defaultValue: "#ff9900",
                  value: "#ff9900",
                ),
                BVariable(
                  name: "secondary_color",
                  description: "Secondary Theme Color",
                  type: "color",
                  defaultValue: "#333333",
                  value: "#333333",
                ),
                BVariable(
                  name: "background_light",
                  description: "Background Light Color",
                  type: "color",
                  defaultValue: "#f4f4f4",
                  value: "#f4f4f4",
                ),
                BVariable(
                  name: "text_dark",
                  description: "Text Dark Color",
                  type: "color",
                  defaultValue: "#222222",
                  value: "#222222",
                ),
                BVariable(
                  name: "border_color",
                  description: "Border Outline Color",
                  type: "color",
                  defaultValue: "#dddddd",
                  value: "#dddddd",
                ),
                BVariable(
                  name: "success_color",
                  description: "Success Highlight Color",
                  type: "color",
                  defaultValue: "#2ec156",
                  value: "#2ec156",
                ),
              ],
            ),
          ],
        ),

        // Custom theme styles referencing Blogger skin variables
        Style(
          attributes: {
            'amp-custom': 'amp-custom',
            'id': 'theme-skin',
            'type': 'text/css',
          },
          children: [
            const Text('''
              :root {
                --primary-color: <data:skin.vars.primary_color/>;
                --secondary-color: <data:skin.vars.secondary_color/>;
                --background-light: <data:skin.vars.background_light/>;
                --text-dark: <data:skin.vars.text_dark/>;
                --border-color: <data:skin.vars.border_color/>;
                --success-color: <data:skin.vars.success_color/>;
              }
              body {
                font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                color: var(--text-dark);
                background-color: #ffffff;
                margin: 0;
                padding: 0;
              }
              header {
                background-color: var(--secondary-color);
                color: #ffffff;
                padding: 10px 20px;
                display: flex;
                justify-content: space-between;
                align-items: center;
                position: sticky;
                top: 0;
                z-index: 100;
              }
              .logo {
                font-size: 1.5rem;
                font-weight: bold;
                color: var(--primary-color);
                text-decoration: none;
              }
              .nav-actions {
                display: flex;
                gap: 15px;
                align-items: center;
              }
              .cart-btn {
                background: none;
                border: none;
                color: #ffffff;
                cursor: pointer;
                position: relative;
                font-size: 1.2rem;
              }
              .cart-badge {
                position: absolute;
                top: -8px;
                right: -8px;
                background-color: var(--primary-color);
                color: var(--secondary-color);
                font-size: 0.75rem;
                font-weight: bold;
                padding: 2px 6px;
                border-radius: 50%;
              }
              .main-container {
                max-width: 1200px;
                margin: 0 auto;
                padding: 20px;
              }
              .product-grid {
                display: grid;
                grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
                gap: 20px;
              }
              .product-card {
                border: 1px solid var(--border-color);
                border-radius: 8px;
                overflow: hidden;
                box-shadow: 0 2px 5px rgba(0,0,0,0.05);
                text-decoration: none;
                color: inherit;
                display: flex;
                flex-direction: column;
                background: #fff;
              }
              .product-img {
                width: 100%;
                height: 250px;
                object-fit: cover;
              }
              .product-info {
                padding: 15px;
                display: flex;
                flex-direction: column;
                flex-grow: 1;
              }
              .product-title {
                font-size: 1.1rem;
                font-weight: bold;
                margin: 0 0 10px 0;
              }
              .product-price {
                font-size: 1.2rem;
                color: var(--primary-color);
                font-weight: bold;
                margin-top: auto;
              }
              .p-badge {
                align-self: flex-start;
                background: rgba(0,0,0,0.05);
                font-size: 0.75rem;
                padding: 2px 8px;
                border-radius: 4px;
                margin-bottom: 8px;
              }
              /* Product Detail styles */
              .detail-container {
                display: grid;
                grid-template-columns: 1fr;
                gap: 30px;
              }
              @media (min-width: 768px) {
                .detail-container {
                  grid-template-columns: 1.2fr 1fr;
                }
              }
              .detail-img-area {
                background: #fdfdfd;
              }
              .detail-info-area {
                display: flex;
                flex-direction: column;
                gap: 15px;
              }
              .stock-badge {
                font-weight: bold;
                padding: 4px 10px;
                border-radius: 4px;
                align-self: flex-start;
                font-size: 0.85rem;
              }
              .in-stock {
                background-color: rgba(46, 193, 86, 0.1);
                color: var(--success-color);
              }
              .out-stock {
                background-color: rgba(234, 67, 53, 0.1);
                color: #ea4335;
              }
              .variant-selector {
                margin: 15px 0;
              }
              .selector-title {
                font-weight: bold;
                margin-bottom: 8px;
                font-size: 0.9rem;
              }
              .option-btn {
                background-color: #fff;
                border: 1px solid var(--border-color);
                padding: 8px 16px;
                margin-right: 8px;
                border-radius: 4px;
                cursor: pointer;
              }
              .option-btn[selected] {
                border-color: var(--primary-color);
                background-color: rgba(255, 153, 0, 0.05);
                font-weight: bold;
              }
              .action-bar {
                display: flex;
                gap: 15px;
                margin-top: 20px;
              }
              .btn-primary {
                background-color: var(--primary-color);
                color: var(--secondary-color);
                border: none;
                padding: 12px 24px;
                font-size: 1rem;
                font-weight: bold;
                border-radius: 6px;
                cursor: pointer;
                flex-grow: 1;
                text-align: center;
              }
              .btn-primary[disabled] {
                background-color: var(--border-color);
                cursor: not-allowed;
              }
              .qty-btn {
                background-color: var(--background-light);
                border: 1px solid var(--border-color);
                width: 40px;
                height: 40px;
                border-radius: 50%;
                font-size: 1.2rem;
                display: flex;
                align-items: center;
                justify-content: center;
                cursor: pointer;
              }
              .qty-val {
                font-size: 1.2rem;
                font-weight: bold;
                width: 30px;
                text-align: center;
              }
              /* Addons list styles */
              .addons-section {
                border-top: 1px solid var(--border-color);
                padding-top: 20px;
                margin-top: 25px;
              }
              .addon-card {
                border: 1px solid var(--border-color);
                padding: 12px;
                border-radius: 6px;
                margin-bottom: 10px;
                display: flex;
                justify-content: space-between;
                align-items: center;
              }
              .addon-info {
                display: flex;
                flex-direction: column;
              }
              .addon-name {
                font-weight: bold;
              }
              .addon-price {
                color: var(--primary-color);
                font-size: 0.9rem;
              }
              /* Sidebar &amp; Cart */
              amp-sidebar {
                width: 320px;
                padding: 20px;
                background: #fff;
                box-shadow: -2px 0 10px rgba(0,0,0,0.1);
              }
              .cart-header {
                display: flex;
                justify-content: space-between;
                align-items: center;
                border-bottom: 1px solid var(--border-color);
                padding-bottom: 15px;
                margin-bottom: 20px;
              }
              .close-sidebar-btn {
                background: none;
                border: none;
                font-size: 1.5rem;
                cursor: pointer;
              }
              .cart-item {
                display: flex;
                gap: 10px;
                padding: 10px 0;
                border-bottom: 1px dashed var(--border-color);
              }
              .cart-item-details {
                flex-grow: 1;
              }
              .cart-total {
                font-size: 1.3rem;
                font-weight: bold;
                display: flex;
                justify-content: space-between;
                margin: 20px 0;
              }
              /* Modals and Lightboxes */
              .lightbox-content {
                background: white;
                max-width: 500px;
                margin: 100px auto;
                padding: 25px;
                border-radius: 8px;
                position: relative;
              }
              .close-lightbox {
                position: absolute;
                top: 15px;
                right: 15px;
                background: none;
                border: none;
                font-size: 1.5rem;
                cursor: pointer;
              }
              .form-group {
                margin-bottom: 15px;
              }
              .form-group label {
                display: block;
                font-weight: bold;
                margin-bottom: 5px;
              }
              .form-control {
                width: 100%;
                padding: 10px;
                border: 1px solid var(--border-color);
                border-radius: 4px;
                box-sizing: border-box;
              }
            ''',
            escape: false,
          ),
        ],
      ),
    ],
    body: [
      // Initialize dynamic states
      // State structure holds cart and current product selection states
      AmpState(
        id: 'cartState',
        children: [
          const RawText(
            '<script type="application/json">{"items": [], "subtotal": 0, "count": 0}</script>',
          ),
        ],
      ),
      AmpState(
        id: 'checkoutState',
        children: [
          const RawText(
            '<script type="application/json">{"pincode": "", "pincodeVerified": false, "address": ""}</script>',
          ),
        ],
      ),
      AmpState(
        id: 'productState',
        children: [
          const RawText(
            '<script type="application/json">'
            '{'
              '"@context": "https://schema.org",'
              '"@base": "118774185466060931/159915394249811386",'
              '"@type": "ProductGroup",'
              '"name": "Premium Organic Cotton Crewneck Collection",'
              '"description": "Premium 100% organic cotton crewneck collection featuring various colors and optional personalization services.",'
              '"brand": {"@type": "Brand", "name": "Antinna Pro Max"},'
              '"image": ["https://picsum.dev/800/600?blur=5", "https://picsum.dev/200/200?static"],'
              '"hasVariant": ['
                '{'
                  '"@id": "variant-midnight-blue",'
                  '"@type": "Product",'
                  '"name": "Elite Crewneck - Midnight Blue (Large)",'
                  '"sku": "EC-MB-L-001",'
                  '"color": "Midnight Blue",'
                  '"size": "Large",'
                  '"price": "38851.00",'
                  '"priceCurrency": "INR",'
                  '"inStock": true'
                '}'
              '],'
              '"addOn": ['
                '{'
                  '"@type": "Offer",'
                  '"price": "499.00",'
                  '"priceCurrency": "INR",'
                  '"itemOffered": {'
                    '"@id": "addon-wrapping",'
                    '"@type": "Service",'
                    '"name": "Premium Gift Wrapping"'
                  '}'
                '}'
              ']'
            '}'
            '</script>',
          ),
        ],
      ),

      // Theme Header / Navigation
      Header(
        children: [
          A(
            attributes: {'href': '/', 'class': 'logo'},
            children: [const Text('Antinna E-Comm')],
          ),
          Div(
            attributes: {'class': 'nav-actions'},
            children: [
              Button(
                attributes: {
                  'class': 'cart-btn',
                  'on': 'tap:cartDrawer.toggle',
                },
                children: [
                  const Text('🛒 Bag'),
                  Span(
                    attributes: {
                      'class': 'cart-badge',
                      'data-amp-bind-text': 'cartState.count',
                    },
                    children: [const Text('0')],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // Hidden raw-jsonld placeholder dynamically filled by Blogger at template-render time
      Div(
        attributes: {
          'id': 'raw-jsonld',
          'style': 'display:none;',
          'expr:data-base': 'data:blog.blogId + "/" + data:blog.postId',
        },
        children: [
          const BData(value: 'post.body'),
        ],
      ),

      // AMP Script running in Web Worker to dynamically load and deep merge schemas at runtime
      AmpScript(
        nodom: 'nodom',
        attributes: {
          'id': 'schemaOverrideScript',
        },
        children: [
          DomComponent(
            'script',
            attributes: {'target': 'amp-script', 'type': 'text/plain'},
            children: [
              const RawText(r'''//<![CDATA[
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

                    // Update AMP State dynamically!
                    AMP.setState({ productState: fullyMergedSchema });
                  }

                  init();
                })();
              //]]>'''),
            ],
          ),
        ],
      ),

      // Main Container - Pure HTML/AMP (No Section or Widget tags)
      Div(
        attributes: {'class': 'main-container'},
        children: [
          // Distinguish between Home / Index list page and Individual Item post page using Blogger conditions
          BIf(
            cond: 'data:view.isMultipleItems',
            children: [
              H1(children: [const Text('Our Collections')]),
              Div(
                attributes: {'class': 'product-grid'},
                children: [
                  BLoop(
                    values: 'data:posts',
                    varName: 'post',
                    children: [
                      A(
                        attributes: {
                          'class': 'product-card',
                          'expr:href': 'data:post.url',
                        },
                        children: [
                          AmpImg(
                            src: 'https://picsum.dev/400/300?text=Product',
                            width: '400',
                            height: '300',
                            layout: 'responsive',
                            attributes: {
                              'class': 'product-img',
                              'expr:src': 'data:post.firstImageUrl',
                              'alt': 'Product Image',
                              'loading': 'lazy',
                            },
                          ),
                          Div(
                            attributes: {'class': 'product-info'},
                            children: [
                              const Div(
                                attributes: {'class': 'p-badge'},
                                children: [Text('Product')],
                              ),
                              H3(
                                attributes: {'class': 'product-title'},
                                children: [
                                  const BData(value: 'post.title'),
                                ],
                              ),
                              Div(
                                attributes: {'class': 'product-price'},
                                children: [
                                  const Text('₹'),
                                  const BData(value: 'post.id'), // Dynamic post identifier
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const BElse(),
              // Item / Post Detail page (Pure HTML & AMP, widget-free)
              Div(
                attributes: {'class': 'detail-container'},
                children: [
                  // Left Image Area
                  Div(
                    attributes: {'class': 'detail-img-area'},
                    children: [
                      AmpCarousel(
                        type: 'slides',
                        width: '400',
                        height: '400',
                        layout: 'responsive',
                        loop: true,
                        children: [
                          AmpImg(
                            src: 'https://picsum.dev/800/600?blur=5',
                            width: '400',
                            height: '400',
                            layout: 'responsive',
                            attributes: {'data-amp-bind-src': 'productState.image[0]'},
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Right Details Area
                  Div(
                    attributes: {'class': 'detail-info-area'},
                    children: [
                      H1(
                        attributes: {
                          'data-amp-bind-text': 'productState.name',
                        },
                        children: [const BData(value: 'post.title')],
                      ),
                      Div(
                        attributes: {
                          'class': 'stock-badge in-stock',
                          'data-amp-bind-class': 'productState.hasVariant[0].inStock ? "stock-badge in-stock" : "stock-badge out-stock"',
                          'data-amp-bind-text': 'productState.hasVariant[0].inStock ? "In Stock" : "Out of Stock"',
                        },
                        children: [const Text('In Stock')],
                      ),
                      P(
                        attributes: {
                          'data-amp-bind-text': 'productState.description',
                        },
                        children: [const BData(value: 'post.body')],
                      ),

                      // Variant Selector (Size)
                      Div(
                        attributes: {'class': 'variant-selector'},
                        children: [
                          const Div(
                            attributes: {'class': 'selector-title'},
                            children: [Text('Select Size')],
                          ),
                          AmpSelector(
                            id: 'sizeSelector',
                            name: 'size',
                            children: [
                              Button(
                                attributes: {
                                  'class': 'option-btn',
                                  'option': 'Large',
                                  'selected': 'selected',
                                },
                                children: [const Text('Large')],
                              ),
                              Button(
                                attributes: {
                                  'class': 'option-btn',
                                  'option': 'Medium',
                                },
                                children: [const Text('Medium')],
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Quantity & Price Row
                      Div(
                        attributes: {
                          'style': 'display:flex; justify-content:space-between; align-items:center; margin: 20px 0;'
                        },
                        children: [
                          Div(
                            attributes: {
                              'style': 'color:var(--primary-color); font-size:1.8rem; font-weight:bold;'
                            },
                            children: [
                              const Text('₹'),
                              Span(
                                attributes: {
                                  'data-amp-bind-text': 'productState.hasVariant[0].price',
                                },
                                children: [const Text('38,851.00')],
                              ),
                            ],
                          ),
                          Div(
                            attributes: {
                              'style': 'display:flex; align-items:center; gap:10px;'
                            },
                            children: [
                              Button(
                                attributes: {
                                  'class': 'qty-btn',
                                  'on': 'tap:AMP.setState({ qty: (qty > 1 ? qty - 1 : 1) })',
                                },
                                children: [const Text('-')],
                              ),
                              Span(
                                attributes: {
                                  'class': 'qty-val',
                                  'data-amp-bind-text': 'qty',
                                },
                                children: [const Text('1')],
                              ),
                              Button(
                                attributes: {
                                  'class': 'qty-btn',
                                  'on': 'tap:AMP.setState({ qty: (qty || 1) + 1 })',
                                },
                                children: [const Text('+')],
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Add-ons Section
                      Div(
                        attributes: {'class': 'addons-section'},
                        children: [
                          H3(children: [const Text('Optional Add-ons')]),
                          Div(
                            attributes: {'class': 'addon-card'},
                            children: [
                              Div(
                                attributes: {'class': 'addon-info'},
                                children: [
                                  Span(
                                    attributes: {
                                      'class': 'addon-name',
                                      'data-amp-bind-text': 'productState.addOn[0].itemOffered.name',
                                    },
                                    children: [const Text('Premium Gift Wrapping')],
                                  ),
                                  Span(
                                    attributes: {
                                      'class': 'addon-price',
                                      'data-amp-bind-text': '"₹" + productState.addOn[0].price',
                                    },
                                    children: [const Text('₹499.00')],
                                  ),
                                ],
                              ),
                              Button(
                                attributes: {
                                  'class': 'option-btn',
                                  'on': 'tap:AMP.setState({ cartState: { items: cartState.items.concat([{"name": productState.addOn[0].itemOffered.name, "price": productState.addOn[0].price, "qty": 1}]), subtotal: cartState.subtotal + 499, count: cartState.count + 1 } })',
                                },
                                children: [const Text('Add Addon')],
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Main Actions
                      Div(
                        attributes: {'class': 'action-bar'},
                        children: [
                          Button(
                            attributes: {
                              'class': 'btn-primary',
                              'on': 'tap:AMP.setState({ cartState: { items: cartState.items.concat([{"name": productState.name, "price": productState.hasVariant[0].price, "qty": qty || 1}]), subtotal: cartState.subtotal + (productState.hasVariant[0].price * (qty || 1)), count: cartState.count + (qty || 1) } }), cartDrawer.open',
                            },
                            children: [const Text('ADD TO BAG')],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // AMP Cart Sidebar Drawer
      AmpSidebar(
        id: 'cartDrawer',
        layout: 'nodisplay',
        side: 'right',
        children: [
          Div(
            attributes: {'class': 'cart-header'},
            children: [
              H2(children: [const Text('Your Bag')]),
              Button(
                attributes: {
                  'class': 'close-sidebar-btn',
                  'on': 'tap:cartDrawer.close',
                },
                children: [const Text('×')],
              ),
            ],
          ),

          // Render Cart Items dynamically using Mustache Template
          AmpList(
            attributes: {
              'data-amp-bind-src': 'cartState.items',
              'layout': 'fixed-height',
              'height': '250',
            },
            children: [
              AmpMustache(
                children: [
                  Div(
                    attributes: {'class': 'cart-item'},
                    children: [
                      Div(
                        attributes: {'class': 'cart-item-details'},
                        children: [
                          Div(
                            attributes: {'style': 'font-weight:bold;'},
                            children: [const Text('{{name}}')],
                          ),
                          Div(
                            attributes: {'style': 'color:var(--primary-color);'},
                            children: [const Text('₹{{price}} x {{qty}}')],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          Div(
            attributes: {'class': 'cart-total'},
            children: [
              const Text('Total:'),
              Span(
                attributes: {'data-amp-bind-text': '"₹" + cartState.subtotal'},
                children: [const Text('₹0.00')],
              ),
            ],
          ),

          // Checkout buttons triggers Geolocation verification
          Button(
            attributes: {
              'class': 'btn-primary',
              'style': 'width:100%; text-align:center;',
              'on': 'tap:locationModal.open, cartDrawer.close',
            },
            children: [const Text('Checkout Order')],
          ),
        ],
      ),

      // AMP Geolocation / Pin verification Lightbox Modal
      AmpLightbox(
        id: 'locationModal',
        layout: 'nodisplay',
        children: [
          Div(
            attributes: {'class': 'lightbox-content'},
            children: [
              Button(
                attributes: {
                  'class': 'close-lightbox',
                  'on': 'tap:locationModal.close',
                },
                children: [const Text('×')],
              ),
              H3(children: [const Text('Verify Delivery Area')]),
              AmpForm(
                method: 'GET',
                actionXhr: 'https://script.google.com/macros/s/AKfycbyca4Xz_AE6Om1okIMf0TQ9EE9uIifQcVZhsDwnZK0K4weG7VD0w3jEzM0aCcuBeoWIIA/exec',
                target: '_top',
                attributes: {
                  'on': 'submit-success:AMP.setState({ checkoutState: { pincodeVerified: event.response.success, address: event.response.address } })',
                },
                children: [
                  Div(
                    attributes: {'class': 'form-group'},
                    children: [
                      Label(
                        attributes: {'for': 'pincodeInput'},
                        children: [const Text('Enter Delivery Pincode')],
                      ),
                      Input(
                        attributes: {
                          'type': 'text',
                          'id': 'pincodeInput',
                          'name': 'pincode',
                          'class': 'form-control',
                          'placeholder': 'e.g., 110001',
                          'required': 'required',
                        },
                      ),
                    ],
                  ),
                  Button(
                    attributes: {
                      'type': 'submit',
                      'class': 'btn-primary',
                      'style': 'width:100%; margin-top:10px;',
                    },
                    children: [const Text('Verify Pincode')],
                  ),
                ],
              ),
              Div(
                attributes: {
                  'style': 'margin-top:20px; padding:10px; border-radius:4px;',
                  'data-amp-bind-style': 'checkoutState.pincodeVerified ? "margin-top:20px; padding:10px; border-radius:4px; background:rgba(46,193,86,0.1); color:var(--success-color);" : "display:none;"',
                },
                children: [
                  const Text('✓ Delivery is available at: '),
                  Span(
                    attributes: {'data-amp-bind-text': 'checkoutState.address'},
                    children: [const Text('')],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // Dummy empty b:section to fully satisfy Blogger parser requirements
      BSection(
        id: 'dummy-layout-section',
        showaddelement: false,
        children: [],
      ),
    ],
  );
}
}
