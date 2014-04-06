require 'sprockets'
require 'sprockets/engines'
require 'htmlcompressor'

module AngularRailsTemplates

  class Template < Tilt::Template
    def self.default_mime_type
      'application/javascript'
    end

    def prepare ; end

    def evaluate(scope, locals, &block)
      template = case File.extname(file)
               when HAML_EXT then HamlTemplate.new(self)
               when SLIM_EXT then SlimTemplate.new(self)
               else
                 BaseTemplate.new(self)
               end

      render_script_template(logical_template_path(scope), template.render)
    end

    protected

    def logical_template_path(scope)
      path = scope.logical_path
      path.gsub!(Regexp.new("^#{configuration.ignore_prefix}"), "")
      "#{path}.html"
    end

    def module_name
      configuration.module_name.inspect
    end

    def configuration
      ::Rails.configuration.angular_templates
    end

    def render_script_template(path, data)
       compressor = HtmlCompressor::Compressor.new(remove_intertag_spaces: true)
       data_final = compressor.compress(data.to_angular_template)
      %Q{
window.AngularRailsTemplates || (window.AngularRailsTemplates = angular.module(#{module_name}, []));

window.AngularRailsTemplates.run(["$templateCache",function($templateCache) {
  $templateCache.put(#{path.inspect}, #{data_final});
}]);
      }
    end

  end
end


class String
  JS_ESCAPE_MAP = {
    '\\'    => '\\\\',
    '</'    => '</',
    "\r\n"  => '',
    "\n"    => '',
    "\r"    => '',
    "\t"    => '',
    '"'     => '\\"',
    "'"     => "\'"
  }

  def to_angular_template
    %("#{json_escape}")
  end

  private

  def json_escape
    gsub(/(\\|<\/|\r\n|\342\200\250|\342\200\251|[\t\n\r"'])/u) { |match|
      JS_ESCAPE_MAP[match]
    }
  end
end

