# frozen_string_literal: true

module ActiveDryDeps
  class DependencyMap

    include TSort

    attr_reader :references

    def initialize
      @references = {}
    end

    def register(receiver, dependencies)
      references[receiver] ||= []
      references[receiver].concat dependencies
      references[receiver].uniq!
    end

    def cycles
      @cycles ||= strongly_connected_components.reject { _1.size == 1 }
    end

    def acyclic?
      cycles.empty?
    end

    def check_cyclic_references
      if references.empty?
        raise ArgumentError, 'No dependency map. You should eager load all your code (or make sure, you are in production environment)'
      end

      return true if acyclic?

      errors =
        cycles.map do |cyclic_references|
          (cyclic_references + [cyclic_references.first]).join(' → ')
        end

      raise CircularDependency, <<~TEXT
        Expected the dependency graph to be acyclic, but it contains the following circular dependencies:
        #{errors.join("\n")}
      TEXT
    end

    private def tsort_each_node(&block)
      references.each_key(&block)
    end

    private def tsort_each_child(node, &block)
      (references[node] || {}).each(&block)
    end

  end
end
