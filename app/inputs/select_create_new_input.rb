class SelectCreateNewInput < SimpleForm::Inputs::CollectionSelectInput
  def input
        template.content_tag(:div, super)
        label_method, value_method = detect_collection_methods
        @builder.collection_select(
          attribute_name, collection, value_method, label_method,
          input_options, input_html_options)
        yield
  end
end