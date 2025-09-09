# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyLLM::Tool do
  describe '#name' do
    it 'converts class name to snake_case and removes _tool suffix' do
      stub_const('SampleTool', Class.new(described_class))
      expect(SampleTool.new.name).to eq('sample')
    end

    # rubocop:disable Naming/AsciiIdentifiers

    it 'normalizes class name Unicode characters to ASCII' do
      stub_const('SàmpleTòol', Class.new(described_class))
      expect(SàmpleTòol.new.name).to eq('sample')
    end

    it 'handles class names with unsupported characters' do
      stub_const('SampleΨTool', Class.new(described_class))
      expect(SampleΨTool.new.name).to eq('sample')
    end

    # rubocop:enable Naming/AsciiIdentifiers

    it 'handles class names without Tool suffix' do
      stub_const('AnotherSample', Class.new(described_class))
      expect(AnotherSample.new.name).to eq('another_sample')
    end

    it 'strips :: for class in module namespace' do
      stub_const('TestModule::SampleTool', Class.new(described_class))
      expect(TestModule::SampleTool.new.name).to eq('test_module--sample')
    end

    it 'handles ASCII-8BIT encoded class names without raising Encoding::CompatibilityError' do
      # This simulates a class name that is ASCII-8BIT encoded
      tool_class = Class.new(described_class)
      ascii_8bit_name = 'SampleTool'.dup.force_encoding('ASCII-8BIT')
      allow(tool_class).to receive(:name).and_return(ascii_8bit_name)
      expect(tool_class.new.name).to eq('sample')
    end
  end

  describe '#input_schema' do
    it 'returns the parameters' do
      stub_const('SampleTool', Class.new(described_class) do
        param :default_param
        param :a_string, type: :string, desc: 'Name'
        param :an_integer, type: :integer, desc: 'An integer'
        param :a_boolean, type: :boolean, desc: 'A boolean'
        param :an_optional_param, required: false
        param :an_enum, type: :string, desc: 'An enum', enum: %w[value1 value2]
        param :a_string_array, type: :array, desc: 'An array', items: { type: 'string' }, required: false
        param :an_object, type: :object, desc: 'An object', required: false, schema: {
          properties: {
            foo: { type: 'string' },
            bar: { type: 'integer' },
            baz: { type: 'boolean' }
          },
          required: %w[foo bar],
          additionalProperties: false
        }
      end)
      expect(SampleTool.new.input_schema).to eq({
                                                  type: 'object',
                                                  properties: {
                                                    default_param: { type: 'string' },
                                                    a_string: { type: 'string', description: 'Name' },
                                                    an_integer: { type: 'integer', description: 'An integer' },
                                                    a_boolean: { type: 'boolean', description: 'A boolean' },
                                                    an_optional_param: { type: 'string' },
                                                    an_enum: {
                                                      type: 'string',
                                                      description: 'An enum',
                                                      enum: %w[value1 value2]
                                                    },
                                                    a_string_array: {
                                                      type: 'array',
                                                      description: 'An array',
                                                      items: { type: 'string' }
                                                    },
                                                    an_object: {
                                                      type: 'object',
                                                      description: 'An object',
                                                      properties: {
                                                        foo: { type: 'string' },
                                                        bar: { type: 'integer' },
                                                        baz: { type: 'boolean' }
                                                      },
                                                      required: %w[foo bar],
                                                      additionalProperties: false
                                                    }
                                                  },
                                                  required: %w[default_param a_string an_integer a_boolean an_enum],
                                                  additionalProperties: false
                                                })
    end
  end
end
