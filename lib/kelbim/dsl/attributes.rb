require 'ostruct'
require 'kelbim/dsl/checker'

module Kelbim
  class DSL
    class EC2
      class LoadBalancer
        class Attributes
          include Checker

          def initialize(load_balancer, &block)
            @error_identifier = "LoadBalancer `#{load_balancer}`"
            @result = {}
            instance_eval(&block)
          end

          def result
            required(:cross_zone_load_balancing, @result[:cross_zone_load_balancing])
            @result
          end

          def method_missing(method_name, *args)
            if args.length == 1
              value = args.first
              call_once(method_name)
              expected_type(value, Hash, Array)
              @result[method_name] = value
            else
              super
            end
          end
        end # Attributes
      end # LoadBalancer
    end # EC2
  end # DSL
end # Kelbim
