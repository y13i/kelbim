require 'kelbim/ext/elb-load-balancer-ext'
require 'kelbim/ext/elb-listener-ext'

module Kelbim
  class Exporter
    class << self
      def export(elb, options = {})
        self.new(elb, options).export
      end
    end # of class methods

    def initialize(elb, options = {})
      @elb = elb
      @options = options
    end

    def export
      result = {}
      lbs = @elb.load_balancers

      ec2s = @options[:ec2s]
      elb_names = @options[:elb_names]

      if ec2s or elb_names
        lbs = lbs.select do |lb|
          (ec2s.nil? or ec2s.include?(lb.vpc_id || 'classic')) &&
          (elb_names.nil? or elb_names.include?(lb.name))
        end
      end

      lbs.each do |lb|
        result[lb.vpc_id] ||= {}
        result[lb.vpc_id][lb.name] = export_load_balancer(lb)
      end

      return result
    end

    private
    def export_load_balancer(load_balancer)
      attrs = {
        :instances    => load_balancer.instances.map {|i| i.id },
        :listeners    => load_balancer.listeners.map {|i| export_listener(i) },
        :health_check => load_balancer.health_check,
        :scheme       => load_balancer.scheme,
        :dns_name     => load_balancer.dns_name,
        :attributes   => load_balancer.attributes,
      }

      if @options[:fetch_policies] and load_balancer.policies.first
        attrs[:policies] = h = {}
        load_balancer.policies.each {|i| h[i.name] = i.type }
      end

      if load_balancer.vpc_id
        attrs[:subnets] = load_balancer.subnets.map {|i| i.id }
        attrs[:security_groups] = load_balancer.security_groups.map {|i| i.name }
      else
        attrs[:availability_zones] = load_balancer.availability_zones.map {|i| i.name }
      end

      return attrs
    end

    def export_listener(listener)
      {
        :protocol           => listener.protocol,
        :port               => listener.port,
        :instance_protocol  => listener.instance_protocol,
        :instance_port      => listener.instance_port,
        :server_certificate => listener.server_certificate,
        :policies           => listener.policies.map {|i| export_policy(i) },
      }
    end

    def export_policy(policy)
      {
        :name       => policy.name,
        :type       => policy.type,
        :attributes => policy.attributes
      }
    end
  end # Exporter
end # Kelbim
