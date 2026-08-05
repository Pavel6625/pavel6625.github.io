# frozen_string_literal: true

require "uri"

# Points every reference to an image in assets/img at the generated WebP
# derivatives, so the originals do not need to be published (or kept in the
# repository) at all.
#
# Three passes over each rendered document:
#
#   1. <img src="/assets/img/X">  -> derivative + srcset + sizes + intrinsic
#      width/height. Templates call _includes/img.html directly, where the
#      layout is known; this pass is for images authors write by hand in
#      Markdown, which no include can reach.
#   2. PhotoSwipe gallery anchors. Their href must move to a derivative *and*
#      their data-pswp-width/height must be restated to match it, or the
#      lightbox sizes every photo wrongly.
#   3. Anything left over - og:image and twitter:image from jekyll-seo-tag, and
#      image URLs inside feed.xml - by direct path substitution.
#
# Anything already under /assets/img/derived/ is left alone.

module ResponsiveImages
  BODY_SIZES = "(min-width: 768px) 672px, 100vw"
  IMG_TAG = /<img\b([^>]*?)\ssrc=(["'])(\/assets\/img\/(?!derived\/)[^"']+)\2([^>]*?)>/i
  ANCHOR = /<a\b[^>]*?\shref=(["'])(\/assets\/img\/(?!derived\/)[^"']+)\1[^>]*?>/im

  module_function

  def derived_base(meta, baseurl)
    "#{baseurl}/assets/img/derived/#{meta['slug']}"
  end

  def widest(meta)
    Array(meta["variants"]).last
  end

  def scaled_height(meta, width)
    (meta["height"].to_f * width / meta["width"].to_f).round
  end

  # Manifest keys are raw paths; HTML may carry the percent-encoded form.
  def lookup(data, path)
    data[path] || data[begin
      require "uri"
      URI.decode_www_form_component(path)
    rescue StandardError
      path
    end]
  end

  def rewrite_images(html, data, baseurl)
    html.gsub(IMG_TAG) do
      whole = Regexp.last_match(0)
      before = Regexp.last_match(1)
      quote  = Regexp.last_match(2)
      src    = Regexp.last_match(3)
      after  = Regexp.last_match(4)
      attrs  = "#{before} #{after}"

      meta = lookup(data, src)
      next whole if meta.nil? || attrs =~ /\ssrcset=/i

      variants = Array(meta["variants"])
      next whole if variants.empty?

      base = derived_base(meta, baseurl)
      srcset = variants.map { |w| "#{base}-#{w}.webp #{w}w" }.join(", ")

      tag = +"<img#{before}"
      tag << " src=#{quote}#{base}-#{widest(meta)}.webp#{quote}"
      tag << " srcset=#{quote}#{srcset}#{quote}"
      tag << " sizes=#{quote}#{BODY_SIZES}#{quote}"
      tag << " width=#{quote}#{meta['width']}#{quote}" unless attrs =~ /\swidth=/i
      tag << " height=#{quote}#{meta['height']}#{quote}" unless attrs =~ /\sheight=/i
      tag << " loading=#{quote}lazy#{quote}" unless attrs =~ /\sloading=/i
      tag << " decoding=#{quote}async#{quote}" unless attrs =~ /\sdecoding=/i
      tag << after << ">"
      tag
    end
  end

  def rewrite_anchors(html, data, baseurl)
    html.gsub(ANCHOR) do
      whole = Regexp.last_match(0)
      href  = Regexp.last_match(2)

      meta = lookup(data, href)
      next whole if meta.nil?

      w = widest(meta)
      base = derived_base(meta, baseurl)
      out = whole.sub(href, "#{base}-#{w}.webp")
      # The lightbox reads these to lay the slide out; they must describe the
      # file actually being opened.
      out = out.sub(/data-pswp-width=(["'])\d+\1/i, "data-pswp-width=\\1#{w}\\1")
      out.sub(/data-pswp-height=(["'])\d+\1/i, "data-pswp-height=\\1#{scaled_height(meta, w)}\\1")
    end
  end

  # The same path shows up raw, with spaces escaped, and fully percent-encoded
  # (Cyrillic filenames come through as %D0%9F%D0%9F...), depending on which
  # component emitted it.
  def path_forms(key)
    forms = [key, key.gsub(" ", "%20")]
    begin
      forms << URI::DEFAULT_PARSER.escape(key)
    rescue StandardError
      nil
    end
    forms.uniq
  end

  def rewrite_leftovers(html, data, baseurl)
    data.each do |key, meta|
      next unless key.is_a?(String) && key.start_with?("/assets/img/")

      replacement = "#{derived_base(meta, baseurl)}-#{widest(meta)}.webp"
      path_forms(key).each { |form| html = html.gsub(form, replacement) }
    end
    html
  end

  def rewrite(html, data, baseurl)
    return html if data.nil? || data.empty?

    html = rewrite_images(html, data, baseurl)
    html = rewrite_anchors(html, data, baseurl)
    rewrite_leftovers(html, data, baseurl)
  end
end

Jekyll::Hooks.register %i[posts pages], :post_render do |doc|
  next unless [".html", ".xml"].include?(doc.output_ext)

  site = doc.site
  doc.output = ResponsiveImages.rewrite(
    doc.output, site.data["images"], site.config["baseurl"].to_s
  )
end
