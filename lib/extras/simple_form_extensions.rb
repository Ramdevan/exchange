module SearchButton
  def search_button(*args, &block)
    template.content_tag :div, :class => "form-group" do
      template.content_tag :div, :class => "form-submit" do
        submit(*args)
      end
    end
  end
end

module WrappedButton

  def wrapped_button(*args, &block)
    template.content_tag :div, :class => "form-group" do
      template.content_tag :div, :class => "form-submit" do

        options = args.extract_options!
        loading = self.object.new_record? ? I18n.t('simple_form.creating') : I18n.t('simple_form.updating')
        options[:"data-loading-text"] = [loading, options[:"data-loading-text"]].compact
        options[:class] = ['btn btn-primary', options[:class]].compact

        args << options

        block_view = block ? template.capture(&block) : nil
        submit_view = options.delete(:no_submit) ? nil : submit(*args)

        cancel_view =
          if cancel_link = options.delete(:cancel)
            class_text = 'btn btn-outline-secondary ml-4'
            cancel_text = options.delete(:cancel_text) || I18n.t('simple_form.buttons.cancel')
            template.link_to(cancel_text, cancel_link, class: class_text)
          end

        [submit_view, cancel_view, block_view].join.html_safe
      end
    end
  end
end
SimpleForm::FormBuilder.send :include, SearchButton
SimpleForm::FormBuilder.send :include, WrappedButton
