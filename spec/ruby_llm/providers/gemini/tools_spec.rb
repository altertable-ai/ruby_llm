# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyLLM::Providers::Gemini::Tools do
  include_context 'with configured RubyLLM'

  # Create a test object that includes the module to access private methods
  let(:test_obj) do
    Object.new.tap do |obj|
      obj.extend(described_class)
    end
  end

  describe '#format_tools' do
    let(:tools) do
      {
        'tool1' => Class.new(RubyLLM::Tool) do
          def name = 'tool1'
          param :a_string, type: :string, desc: 'A string'
        end.new
      }
    end

    it 'formats tools' do
      result = test_obj.send(:format_tools, tools)

      expect(result).to eq(
        [{ functionDeclarations: [{ name: 'tool1',
                                    parameters: { type: 'OBJECT', properties: { a_string: { type: 'STRING', description: 'A string' } },
                                                  required: ['a_string'], additionalProperties: false } }] }]
      )
    end
  end
end
