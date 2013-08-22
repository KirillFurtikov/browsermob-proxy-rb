require 'spec_helper'

describe "Proxy + WebDriver" do
  let(:driver)  { Selenium::WebDriver.for :firefox, :profile => profile }
  let(:proxy) { new_proxy }
  let(:wait) { Selenium::WebDriver::Wait.new(:timeout => 10) }

  let(:profile) {
    pr = Selenium::WebDriver::Firefox::Profile.new
    pr.proxy = proxy.selenium_proxy

    pr
  }

  after {
    driver.quit
    proxy.close
  }

  it "should fetch a HAR" do
    proxy.new_har("1")
    driver.get url_for("1.html")
    wait.until { driver.title == '1' }

    proxy.new_page "2"
    driver.get url_for("2.html")
    wait.until { driver.title == '2' }

    har = proxy.har

    har.should be_kind_of(HAR::Archive)
    har.pages.size.should == 2
  end

  it "should fetch a HAR and capture headers" do
    proxy.new_har("2", :capture_headers => true)

    driver.get url_for("2.html")
    wait.until { driver.title == '2' }

    entry = proxy.har.entries.first
    entry.should_not be_nil

    entry.request.headers.should_not be_empty
  end

  it "should set whitelist and blacklist" do
    proxy.whitelist(/example\.com/, 201)
    proxy.blacklist(/bad\.com/, 404)
  end

  it "should set headers" do
    proxy.headers('Content-Type' => "text/html")
  end

  it "should set limits" do
    proxy.limit(:downstream_kbps => 100, :upstream_kbps => 100, :latency => 2)
  end

  it 'should remap given DNS hosts' do
    host = '1.2.3.4'
    proxy.remap_dns_hosts(host => '127.0.0.2')
    uri = URI(url_for('1.html'))
    uri.host = host
    driver.get uri
    wait.until { driver.title == '1' }
    driver.find_element(:link_text => "2").click
  end
end
