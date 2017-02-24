# Copyright 2016 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


require "google/cloud/errors"
require "google/cloud/language/credentials"
require "google/cloud/language/version"
require "google/cloud/language/v1"

module Google
  module Cloud
    module Language
      ##
      # @private Represents the gRPC Language service, including all the API
      # methods.
      class Service
        attr_accessor :project, :credentials, :host, :client_config, :timeout

        ##
        # Creates a new Service instance.
        def initialize project, credentials, host: nil, client_config: nil,
                       timeout: nil
          @project = project
          @credentials = credentials
          @host = host || V1::LanguageServiceClient::SERVICE_ADDRESS
          @client_config = client_config || {}
          @timeout = timeout
        end

        def channel
          require "grpc"
          GRPC::Core::Channel.new host, nil, chan_creds
        end

        def chan_creds
          return credentials if insecure?
          require "grpc"
          GRPC::Core::ChannelCredentials.new.compose \
            GRPC::Core::CallCredentials.new credentials.client.updater_proc
        end

        def service
          return mocked_service if mocked_service
          @service ||= V1::LanguageServiceClient.new(
            service_path: host,
            channel: channel,
            timeout: timeout,
            client_config: client_config,
            app_name: "gcloud-ruby",
            app_version: Google::Cloud::Language::VERSION)
        end
        attr_accessor :mocked_service

        def insecure?
          credentials == :this_channel_is_insecure
        end

        ##
        # Returns API::BatchAnnotateImagesResponse
        def annotate doc_grpc, syntax: false, entities: false, sentiment: false,
                     encoding: nil
          if syntax == false && entities == false && sentiment == false
            syntax = true
            entities = true
            sentiment = true
          end
          features = V1::AnnotateTextRequest::Features.new(
            extract_syntax: syntax, extract_entities: entities,
            extract_document_sentiment: sentiment)
          encoding = verify_encoding! encoding
          execute do
            service.annotate_text doc_grpc, features, encoding,
                                  options: default_options
          end
        end

        def syntax doc_grpc, encoding: nil
          encoding = verify_encoding! encoding
          execute do
            service.analyze_syntax doc_grpc, encoding,
                                   options: default_options
          end
        end

        def entities doc_grpc, encoding: nil
          encoding = verify_encoding! encoding
          execute do
            service.analyze_entities doc_grpc, encoding,
                                     options: default_options
          end
        end

        def sentiment doc_grpc, encoding: nil
          encoding = verify_encoding! encoding
          execute do
            service.analyze_sentiment doc_grpc, encoding_type: encoding,
                                                options: default_options
          end
        end

        def inspect
          "#{self.class}(#{@project})"
        end

        protected

        def verify_encoding! encoding
          # TODO: verify encoding against V1::EncodingType
          { "utf8"   => :UTF8,
            "utf-8"  => :UTF8,
            "utf16"  => :UTF16,
            "utf-16" => :UTF16,
            "utf32"  => :UTF32,
            "utf-32" => :UTF32
          }[String(encoding).downcase] || :UTF8
        end

        def default_headers
          { "google-cloud-resource-prefix" => "projects/#{@project}" }
        end

        def default_options
          Google::Gax::CallOptions.new kwargs: default_headers
        end

        def execute
          yield
        rescue Google::Gax::GaxError => e
          # GaxError wraps BadStatus, but exposes it as #cause
          raise Google::Cloud::Error.from_error(e.cause)
        end
      end
    end
  end
end
