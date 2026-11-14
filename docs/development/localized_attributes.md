# Localized attributes

Every string a person reads in NL Venues is localized: static copy through I18n, stored content through Mobility translated attributes with an explicit `type: :string` or `backend: :action_text`, never plain columns.

This diagram is the app's inventory of its own translated attributes (the models and extension concerns in this repository, not the gem's):

- Mermaid source, rendered inline by GitHub: [localized_attributes.mmd](localized_attributes.mmd)

It is generated. After adding, removing or retyping any `translates` attribute, regenerate it and commit it with the change:

```bash
COMPOSE_PROJECT_NAME=nl-venues bin/export_localized_attributes            # regenerate
COMPOSE_PROJECT_NAME=nl-venues bin/export_localized_attributes --check    # read-only: fails if stale or any translates is untyped
```

`spec/scripts/localized_attribute_diagram_spec.rb` runs the same check in CI. The generator, `scripts/localized_attribute_diagram.rb`, is a copy of the Community Engine one so this app needs no newer gem. Change it in community-engine-rails first and copy it back.
