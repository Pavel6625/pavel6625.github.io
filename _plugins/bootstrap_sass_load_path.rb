# frozen_string_literal: true

# Puts the installed bootstrap gem on Sass' load path.
#
# This used to live in _config.yml as two hardcoded absolute paths
# ("C:/Ruby33-x64/lib/ruby/gems/3.3.0/gems/bootstrap-5.3.5" and a vendor/bundle
# equivalent), which pinned the machine, the Ruby version and the Bootstrap
# version all at once. Resolving the gem here keeps the build working after any
# of the three change.
Jekyll::Hooks.register :site, :after_init do |site|
  spec = Gem.loaded_specs["bootstrap"] || begin
    Gem::Specification.find_by_name("bootstrap")
  rescue Gem::LoadError
    nil
  end

  unless spec
    Jekyll.logger.warn "Bootstrap:", "gem not found; @import of _bootstrap.scss will fail"
    next
  end

  sass = site.config["sass"] ||= {}
  load_paths = sass["load_paths"] ||= []
  load_paths = sass["load_paths"] = Array(load_paths)
  load_paths << spec.gem_dir unless load_paths.include?(spec.gem_dir)

  Jekyll.logger.info "Bootstrap:", "sass load path #{spec.gem_dir}"
end
