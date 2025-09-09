# frozen_string_literal: true

module RubyLLM
  module Providers
    class Gemini
      # Tools methods for the Gemini API implementation
      module Tools
        def format_tools(tools)
          return [] if tools.empty?

          [{
            functionDeclarations: tools.values.map { |tool| function_declaration_for(tool) }
          }]
        end

        def extract_tool_calls(data)
          return nil unless data

          candidate = data.is_a?(Hash) ? data.dig('candidates', 0) : nil
          return nil unless candidate

          parts = candidate.dig('content', 'parts')
          return nil unless parts.is_a?(Array)

          function_call_part = parts.find { |p| p['functionCall'] }
          return nil unless function_call_part

          function_data = function_call_part['functionCall']
          return nil unless function_data

          id = SecureRandom.uuid

          {
            id => ToolCall.new(
              id: id,
              name: function_data['name'],
              arguments: function_data['args']
            )
          }
        end

        private

        def function_declaration_for(tool)
          {
            name: tool.name,
            description: tool.description,
            parameters: tool.parameters.any? ? gemini_input_schema(tool.input_schema) : nil
          }.compact
        end

        # FIXME: this should rely on the samed code than `convert_schema_to_gemini`
        def gemini_input_schema(schema)
          case schema
          when Hash
            schema.each do |key, value|
              if key == :type
                schema[:type] = case value.to_s.downcase
                                when 'integer', 'number', 'float' then 'NUMBER'
                                when 'boolean' then 'BOOLEAN'
                                when 'array' then 'ARRAY'
                                when 'object' then 'OBJECT'
                                else 'STRING'
                                end
              else
                schema[key] = gemini_input_schema(value)
              end
            end
          when Array
            schema.each { |item| gemini_input_schema(item) }
          else
            schema
          end
        end
      end
    end
  end
end
