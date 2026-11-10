# frozen_string_literal: true

# Writes docs/development/localized_attributes.mmd: the localized (Mobility) attributes this app declares
# itself, in its own models and extension concerns. The gem's attributes are not drawn.
# Run with bin/export_localized_attributes. Flags:
#   --check   write nothing; exit 1 when the diagram is stale or any translates call is untyped
require 'pathname'
require_relative 'localized_attribute_diagram'

Rails.application.eager_load!

root = Rails.root.to_s
output = File.join(root, 'docs/development/localized_attributes.mmd')
models = ActiveRecord::Base.descendants.select { |m| m.name && !m.abstract_class? && m.respond_to?(:mobility_attributes) }
declarations = LocalizedAttributeDiagram::Scanner.scan_roots([root], base: root)
diagram = LocalizedAttributeDiagram.new(models: models, declarations: declarations, title: 'NL Venues',
                                        generator: 'scripts/export_localized_attributes.rb')

untyped = diagram.untyped_declarations
untyped.each { |d| warn "UNTYPED translates (add type: :string or :text): #{d.location} #{d.attributes.join(', ')}" }

if ARGV.include?('--check')
  warn "#{output} is stale. Run bin/export_localized_attributes and commit it." unless diagram.current?(output)
  exit(diagram.current?(output) && untyped.empty? ? 0 : 1)
end

File.write(output, diagram.to_mermaid)
puts "Wrote #{Pathname.new(output).relative_path_from(Pathname.new(root))} (#{diagram.entries.size} attributes)"
exit(untyped.empty? ? 0 : 1)
