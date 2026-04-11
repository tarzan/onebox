# frozen_string_literal: true

require "spec_helper"

describe Onebox::Engine::TwitterStatusOnebox do
  shared_examples_for "#to_html" do
    it "includes tweet" do
      expect(html).to include(tweet_content)
    end

    it "includes name" do
      expect(html).to include(full_name)
    end

    it "includes username" do
      expect(html).to include(screen_name)
    end

    it "includes user avatar" do
      expect(html).to include(avatar)
    end

    it "includes twitter link" do
      expect(html).to include(link)
    end
  end

  shared_examples "#to_html with metrics" do
    it "gets the correct timestamp" do
      expect(html).to include(timestamp)
    end

    it "includes twitter likes" do
      expect(html).to include(favorite_count)
    end

    it "includes twitter retweets" do
      expect(html).to include(retweets_count)
    end
  end

  shared_context "standard tweet info" do
    before :all do
      @link = "https://twitter.com/vyki_e/status/363116819147538433"
      @onebox_fixture = "twitterstatus"
    end

    let(:full_name) { "Vyki Englert" }
    let(:screen_name) { "vyki_e" }
    let(:avatar) { "732349210264133632/RTNgZLrm" }
    let(:link) { @link }
  end

  shared_context "quoted tweet info" do
    before :all do
      @link = "https://twitter.com/Metallica/status/1128068672289890305"
      @onebox_fixture = "twitterstatus_quoted"
    end

    let(:full_name) { "Metallica" }
    let(:screen_name) { "Metallica" }
    let(:avatar) { "profile_images/766360293953802240/kt0hiSmv" }
    let(:link) { @link }
  end

  shared_examples "includes quoted tweet data" do
    it 'includes quoted tweet' do
      expect(html).to include("If you bought a ticket for tonight&#39;s @Metallica show at Stade de France, you have helped")
    end

    it "includes quoted tweet name" do
      expect(html).to include("All Within My Hands Foundation")
    end

    it "includes quoted username" do
      expect(html).to include("AWMHFoundation")
    end

    it "includes quoted tweet link" do
      expect(html).to include("https://twitter.com/AWMHFoundation/status/1127646016931487744")
    end
  end

  context "with html" do
    context "with a standard tweet" do
      let(:tweet_content) { "I'm a sucker for pledges." }

      include_context "standard tweet info"
      include_context "engines"

      it_behaves_like "an engine"
      it_behaves_like "#to_html"
    end

    context "with a quoted tweet" do
      let(:tweet_content) do
        "Thank you to everyone who came out for #MetInParis last night for helping us support @EMMAUSolidarite &amp;"
      end

      include_context "quoted tweet info"
      include_context "engines"

      it_behaves_like "an engine"
      it_behaves_like '#to_html'
    end
  end

  context "with twitter client" do
    before(:each) do
      @twitter_client = instance_double(
        "TwitterClient", status: api_response, prettify_tweet: tweet_content, twitter_credentials_missing?: false
      )

      Onebox.options = { twitter_client: @twitter_client }
    end

    after(:each) do
      Onebox.options = { twitter_client: nil }
    end

    context "with a standard tweet" do
      let(:tweet_content) do
        "I'm a sucker for pledges.  <a href='https://twitter.com/Peers' target='_blank'>@Peers</a> Pledge <a href='https://twitter.com/search?q=%23sharingeconomy' target='_blank'>#sharingeconomy</a> <a target='_blank' href='http://www.peers.org/action/peers-pledgea/'>peers.org/action/peers-p…</a>"
      end
      let(:timestamp) { "1:59 AM - 2 Aug 2013" }
      let(:favorite_count) { "0" }
      let(:retweets_count) { "0" }
      let(:api_response) do
        {
          data: {
            id: "363116819147538433",
            text: "I'm a sucker for pledges. @Peers Pledge #sharingeconomy http://t.co/T4Sc47KAzh",
            created_at: "2013-08-02T01:59:30.000Z",
            public_metrics: {
              like_count: 0,
              retweet_count: 0,
            },
          },
          includes: {
            users: [
              {
                id: "1087064150",
                name: "Vyki Englert",
                username: "vyki_e",
                profile_image_url: "https://pbs.twimg.com/profile_images/732349210264133632/RTNgZLrm_normal.jpg",
              },
            ],
          },
        }
      end

      include_context "standard tweet info"
      include_context "engines"

      it_behaves_like "an engine"
      it_behaves_like "#to_html"
      it_behaves_like "#to_html with metrics"
    end

    context "with quoted tweet" do
      let(:tweet_content) do
        "Thank you to everyone who came out for <a href='https://twitter.com/search?q=%23MetInParis' target='_blank'>#MetInParis</a> last night for helping us support <a href='https://twitter.com/EMMAUSolidarite' target='_blank'>@EMMAUSolidarite</a> &amp; <a href='https://twitter.com/PompiersParis' target='_blank'>@PompiersParis</a>. <a href='https://twitter.com/search?q=%23AWMH' target='_blank'>#AWMH</a> <a href='https://twitter.com/search?q=%23MetalicaGivesBack' target='_blank'>#MetalicaGivesBack</a> <a href=\"https://t.co/gLtZSdDFmN\" target=\"_blank\">https://t.co/gLtZSdDFmN</a>"
      end
      let(:timestamp) { "10:45 PM - 13 May 2019" }
      let(:favorite_count) { "1.7K" }
      let(:retweets_count) { "201" }
      let(:api_response) do
        {
          data: {
            id: "1128068672289890305",
            text: "Thank you to everyone who came out for #MetInParis last night for helping us support @EMMAUSolidarite & @PompiersParis. #AWMH #MetalicaGivesBack https://t.co/gLtZSdDFmN",
            created_at: "2019-05-13T22:45:04.000Z",
            public_metrics: {
              like_count: 1664,
              retweet_count: 201,
            },
            referenced_tweets: [
              { type: "quoted", id: "1127646016931487744" },
            ],
          },
          includes: {
            users: [
              {
                id: "238475531",
                name: "Metallica",
                username: "Metallica",
                profile_image_url: "https://pbs.twimg.com/profile_images/766360293953802240/kt0hiSmv_normal.jpg",
              },
              {
                id: "886959980254871552",
                name: "All Within My Hands Foundation",
                username: "AWMHFoundation",
              },
            ],
            tweets: [
              {
                id: "1127646016931487744",
                text: "If you bought a ticket for tonight's @Metallica show at Stade de France, you have helped contribute to @EMMAUSolidarite & @PompiersParis. #MetallicaGivesBack #AWMH #MetInParis https://t.co/wlUtDQbQEK",
                author_id: "886959980254871552",
              },
            ],
          },
        }
      end

      include_context "quoted tweet info"
      include_context "engines"

      it_behaves_like "an engine"
      it_behaves_like '#to_html'
      it_behaves_like "#to_html with metrics"
      it_behaves_like "includes quoted tweet data"
    end
  end
end
