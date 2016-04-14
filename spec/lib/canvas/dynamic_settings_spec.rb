require_relative "../../spec_helper"
require 'diplomat'

module Canvas
  describe DynamicSettings do
    before do
      @cached_config = DynamicSettings.config
    end

    after do
      Diplomat::Kv.unstub(:put)
      begin
        DynamicSettings.config = @cached_config
      rescue Faraday::ConnectionFailed
        # don't fail the test if there is no consul running
      end
    end
    let(:parent_key){ "rich-content-service" }
    let(:diplomat_read_options){ { recurse: true, consistency: 'stale' } }

    describe ".config=" do

      let(:valid_config) do
        {
          "host"      =>"consul",
          "port"      => 8500,
          "ssl"       => true,
          "acl_token" => "some-long-string"
        }
      end

      it "configures diplomat when config is set" do
        Diplomat::Kv.stubs(:put)
        DynamicSettings.config = valid_config
        expect(Diplomat.configuration.url).to eq("https://consul:8500")
      end

      it "sends initial config data by de-nesting a hash into keys" do
        init_data = {
          "rich-content-service" => {
            "app-host" => "rce.docker",
            "cdn-host" => "rce.docker"
          }
        }

        Diplomat::Kv.expects(:put)
          .with("/config/canvas/rich-content-service/app-host", "rce.docker")
          .at_least_once
        Diplomat::Kv.expects(:put)
          .with("/config/canvas/rich-content-service/cdn-host", "rce.docker")
          .at_least_once

        DynamicSettings.config = valid_config.merge({
          "init_values" => init_data
        })

      end
    end

    describe ".find" do

      # we don't need to interact with a real consul for unit tests
      before(:each) do
        DynamicSettings.config = {} # just to be not nil
        Diplomat::Kv.stubs(:put)
        Diplomat::Kv.stubs(:get).
          with("/config/canvas/#{parent_key}", diplomat_read_options).
          returns(
            [
              { key: "#{parent_key}/app-host", value: "rce.insops.com"},
              { key: "#{parent_key}/cdn-host", value: "asdfasdf.cloudfront.com"}
            ]
          )
      end

      it "explodes when trying to access it without a config file" do
        DynamicSettings.config = nil
        expect{ DynamicSettings.find(parent_key) }.to(
          raise_error(DynamicSettings::ConsulError)
        )
      end

      it "loads the children of a k/v node as a hash" do
        rce_settings = DynamicSettings.find(parent_key)
        expect(rce_settings).to eq({
          "app-host" => "rce.insops.com",
          "cdn-host" => "asdfasdf.cloudfront.com"
        })
      end

      it "uses the last found value on catastrophic outage" do
        DynamicSettings.reset_cache!(hard: true)
        DynamicSettings.find(parent_key)
        # some values are now stored in case of connection failure
        Diplomat::Kv.stubs(:get).
          with("/config/canvas/#{parent_key}", diplomat_read_options).
          raises(Faraday::ConnectionFailed, "could not contact consul")

        rce_settings = DynamicSettings.find(parent_key)
        expect(rce_settings).to eq({
          "app-host" => "rce.insops.com",
          "cdn-host" => "asdfasdf.cloudfront.com"
        })
      end

      it "cant recover with no value cached for connection failure" do
        DynamicSettings.reset_cache!(hard: true)
        Diplomat::Kv.stubs(:get).
          with("/config/canvas/#{parent_key}", diplomat_read_options).
          raises(Faraday::ConnectionFailed, "could not contact consul")

        expect{ DynamicSettings.find(parent_key) }.to(
          raise_error(Faraday::ConnectionFailed)
        )
      end
    end

    describe ".from_cache" do
      before(:each){ DynamicSettings.config = {} } # just to be not nil
      after(:each){ DynamicSettings.reset_cache! }

      def stub_consul_with(value)
        Diplomat::Kv.stubs(:get).with("/config/canvas/#{parent_key}", diplomat_read_options).returns(
          [{ key: "#{parent_key}/app-host", value: value}]
        )
      end

      it "only queries consul the first time" do
        Diplomat::Kv.expects(:get).
          with("/config/canvas/#{parent_key}", diplomat_read_options).
          once. # and only once, going to hit it several times
          returns([{ key: "#{parent_key}/app-host", value: "rce.insops.com"}])
        5.times{ DynamicSettings.from_cache(parent_key) }
        value = DynamicSettings.from_cache(parent_key)
        expect(value["app-host"]).to eq("rce.insops.com")
      end

      it "definitely doesnt pickup new values once cached" do
        stub_consul_with("rce.insops.com")
        value = DynamicSettings.from_cache(parent_key)
        expect(value["app-host"]).to eq("rce.insops.com")
        stub_consul_with("CHANGED VALUE")
        value = DynamicSettings.from_cache(parent_key)
        expect(value["app-host"]).to eq("rce.insops.com")
      end

      it "returns new values after a cache clear" do
        stub_consul_with("rce.insops.com")
        DynamicSettings.from_cache(parent_key)
        stub_consul_with("CHANGED VALUE")
        DynamicSettings.reset_cache!
        value = DynamicSettings.from_cache(parent_key)
        expect(value["app-host"]).to eq("CHANGED VALUE")
      end

      it "caches values with timeouts" do
        stub_consul_with("rce.insops.com")
        value = DynamicSettings.from_cache(parent_key, expires_in: 5.minutes)
        expect(value["app-host"]).to eq("rce.insops.com")
        stub_consul_with("CHANGED VALUE")
        value = DynamicSettings.from_cache(parent_key, expires_in: 5.minutes)
        expect(value["app-host"]).to eq("rce.insops.com")
      end

      it "loads new values when timeout is past" do
        stub_consul_with("rce.insops.com")
        value = DynamicSettings.from_cache(parent_key, expires_in: 5.minutes)
        Timecop.travel(Time.zone.now + 6.minutes) do
          stub_consul_with("CHANGED VALUE")
          value = DynamicSettings.from_cache(parent_key, expires_in: 5.minutes)
          expect(value["app-host"]).to eq("CHANGED VALUE")
        end
      end

      it "accepts a timeout on a previously inifinity key" do
        stub_consul_with("rce.insops.com")
        value = DynamicSettings.from_cache(parent_key)
        Timecop.travel(Time.zone.now + 11.minutes) do
          stub_consul_with("CHANGED VALUE")
          value = DynamicSettings.from_cache(parent_key, expires_in: 10.minutes)
          expect(value["app-host"]).to eq("CHANGED VALUE")
        end
      end

      context "using catastrophic cache fallback" do
        before(:each) do
          stub_consul_with("rce.insops.com")
          DynamicSettings.from_cache(parent_key) # prime cache
          Timecop.travel(Time.zone.now + 11.minutes)
        end

        after(:each) do
          Timecop.return
          Canvas.unstub(:timeout_protection)
        end

        it "still returns old values if connection fails after timeout" do
          Diplomat::Kv.stubs(:get).
            with("/config/canvas/#{parent_key}", diplomat_read_options).
            raises(Faraday::ConnectionFailed, "could not contact consul")
          value = DynamicSettings.from_cache(parent_key, expires_in: 10.minutes)
          expect(value["app-host"]).to eq("rce.insops.com")
        end

        it "returns old value during connection timeout" do
          Canvas.stubs(:timeout_protection).with('consul', raise_on_timeout: true).
            raises(Timeout::Error, 'consul took too long')
          value = DynamicSettings.from_cache(parent_key, expires_in: 10.minutes)
          expect(value["app-host"]).to eq("rce.insops.com")
        end

        it "uses cached values during TimeoutCutoff events" do
          Canvas.stubs(:timeout_protection).with('consul', raise_on_timeout: true).
            raises(TimeoutCutoff, 'consul took too long too many times')
          value = DynamicSettings.from_cache(parent_key, expires_in: 10.minutes)
          expect(value["app-host"]).to eq("rce.insops.com")
        end
      end
    end


  end
end
