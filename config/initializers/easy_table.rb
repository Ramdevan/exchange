module EasyTable
  module Components
    module Columns
      def column_with_custom(title, label_or_opts = nil, opts = {}, &block)
        if @options[:model]
          label_or_opts ||= {}
          label_or_opts.merge!({model: @options[:model]})
        end

        if @options[:scope]
          label_or_opts ||= {}
          label_or_opts.merge!({scope: @options[:scope]})
        end

        column_without_custom(title, label_or_opts, opts, &block)
      end

      # alias_method :column, :customize               #old line

      if self.method_defined?(:customize)     #new changes
        alias_method :custom, :customize
      end

     
    end

    module Base
      def translate_with_custom(key)
        if @opts[:model]
          @opts[:model].human_attribute_name(@title)
        elsif @opts[:scope]
          I18n.t("easy_table.#{@opts[:scope]}.#{@title}")
        else
          translate_without_custom(key)
        end
      end

      #  alias_method :translate, :customize         #old line

      if self.method_defined?(:customize)      #new changes
        alias_method :custom, :customize
      end

     
    end
  end
end

