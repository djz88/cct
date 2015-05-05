require "csv"

module Cct
  module Commands
    # Is included into controller node and provides method #openstack as namespace
    # for openstack client commands
    module Openstack
      # @return [Openstack] object that provides the openstack client commands
      def openstack
        @openstack ||= Openstack::Client.new(self)
      end

      # Proxy object for accessing all openstack client commands.
      # If a new command is added, e.g. in lib/cct/commands/openstack/new_command.rb,
      # don't forget to add it also into the #initialize method including the attr_readers
      class Client
        COMMAND = "openstack"

        # @return [Openstack::Image] for accessing openstack.image subcommands
        attr_reader :image
        # @return [Openstack::User] for accessing openstack.user subcommands
        attr_reader :user

        # @param [Cct::Node] as the receiver for the openstack client
        def initialize node
          @image = Openstack::Image.new(node)
          @user = Openstack::User.new(node)
        end
      end

      # Parent class to inherit from for all openstack client commands
      # @example Implementation of openstack.user subcommands
      #
      # class User < Command
      #   self.command = "user" # This will set the namespace: openstack.user
      #
      #   # Access with `control_node.openstack.user.create("Mozart", password: "Wien")`
      #   def create name, options={}
      #     super do |params|
      #       params.add :optional, password: "--password"
      #       params.add :optional, email:    "--email"
      #       params.add :optional, project:  "--project"
      #       params.add :optional, enable:   "--enable",  param_type: :switch
      #       params.add :optional, disable:  "--disable", param_type: :switch
      #     end
      #   end
      # end
      class Command
        class << self
          attr_accessor :command
        end

        attr_reader :node, :log, :params

        def initialize node
          @node = node
          @log = node.log
          @params = Params.new
        end

        def exec! subcommand, *params
          node.exec!(Openstack::Client::COMMAND, self.class.command, subcommand, *params)
        end

        def create name, options={}
          yield params
          params = ["create", name, "--format=shell"].concat(params.extract!(options))
          OpenStruct.new(shell_parse(exec!(params).output))
        end

        def delete id_or_name
          exec!("delete", id_or_name)
        end

        def list
          user_row = Struct.new(:id, :name)
          result = exec!("list", "--format=csv").output
          csv_parse(result).map do |row|
            user_row.new(*row)
          end
        end

        def show id_or_name
          OpenStruct.new(shell_parse(exec!("show", id_or_name, "--format=shell").output))
        end

        private

        def csv_parse csv_data, header: false
          result = CSV.parse(csv_data)
          header ? result : result.drop(1)
        end

        def shell_parse shell_data
          shell_data.gsub("\"", "").split("\n").reduce({}) do |result, shell_pair|
            attribute, value = shell_pair.split("=")
            result[attribute] = value
            result
          end
        end

        class Params
          attr_reader :mandatory, :optional, :all

          def initialize
            @mandatory = []
            @optional = []
            @shell = []
          end

          def add type=:mandatory, params
            case type
            when :mandatory
              mandatory.push(params)
            when :optional
              optional.push(params)
            else
              raise "Type '#{type}' for parameters not allowed"
            end
          end

          def extract! options
            extract_mandatory(options)
            extract_optional(options)
            shell
          end

          private

          def extract_mandatory options
            mandatory.each do |param|
              param_type = param.delete(:param_type)
              param.each_pair do |key, value|
                raise "Parameter '#{key}' is mandatory" unless options[key]

                case param_type
                when :switch
                  shell.push(value)
                  next
                else
                  shell.push("#{key}=#{options[key]}")
                end
              end
            end
          end

          def extract_optional options
            optional.each do |param|
              param_type = param.delete(:param_type)
              param.each_pair do |key, value|
                next unless options[key]

                case param_type
                when :switch
                  shell.push(value)
                  next
                else
                  shell.push("#{key}=#{options[key]}")
                end
              end
            end
          end

        end
      end

    end
  end
end

require 'cct/commands/openstack/image'
require 'cct/commands/openstack/user'

