require 'chef-ramsay/test'
require 'chef-ramsay/helpers/os'
require 'chef-ramsay/helpers/filetools'

module Ramsay
  class Test
    class Unit < Ramsay::Test

      include Ramsay::Helper::OS
      include Ramsay::Helper::FileTools

      attr_reader :test_root
      attr_reader :tested_cookbook # This cookbook.
      def initialize
        super
        @test_root = File.join(self.root_dir, 'unit', 'ramsay', 'recipes')
        @tested_cookbook = File.basename(Dir.pwd)
      end

      def framework
        "chefspec"
      end

      def test_file(recipe = '')
        "#{test_root}/#{recipe}_spec.rb"
      end

      def preamble(cookbook = '', recipe = '')
        "# #{test_file(recipe)}\n" \
        "\n" \
        "require '#{framework}'\n" \
        "\n" \
        "describe '#{cookbook}::#{recipe}' do\n" \
        "  let(:chef_run) { ChefSpec::ServerRunner.new(platform: '#{os[:platform]}', version: '#{os[:version]}').converge(described_recipe) }"
      end

      def write_test(resource = nil)
        state_attrs = [] # Attribute hash to be used with #with()
        resource.state.each do |attr, value|
          next if value.nil? or value.empty?
          state_attrs << "#{attr}: '#{value}'"
        end
        test_output = ["\n  it '#{resource.action.first}s #{resource.declared_type} \"#{resource.name}\"' do"]
        if state_attrs.empty?
          test_output << "    expect(chef_run).to #{resource.action.first}_#{resource.declared_type}('#{resource.name}')"
        else
          test_output << "    expect(chef_run).to #{resource.action.first}_#{resource.declared_type}('#{resource.name}').with(#{state_attrs.join(', ')})"
        end
        test_output << "  end\n"
        test_output.join("\n")
      end

      def generate(recipe_resources = {})
        test_files_written = []
        recipe_resources.each do |canonical_recipe, resources|
          (cookbook, recipe) = canonical_recipe.split('::')
          # Only write unit tests for the cookbook we're in.
          next unless cookbook == tested_cookbook
          content = [preamble]
          resources.each do |resource|
            content << write_test(resource)
          end
          content << "end"
          test_file_name = test_file(recipe)
          write_file(test_file_name, content.join("\n"))
          test_files_written << test_file_name
        end

        unless test_files_written.empty?
          puts "Wrote the following unit test files:"
          test_files_written.each do |f|
            puts "\t#{f}"
          end
        end

      end

    end
  end
end
