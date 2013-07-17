describe Bosh::Cloudfoundry::Validations::DnsIpMappingValidation do
  subject { Bosh::Cloudfoundry::Validations::DnsIpMappingValidation.new("some.domain.com", "1.2.3.4") }

  it "resolves valid DNS -> single IP mapping" do
    subject.should_receive(:resolve_dns).with("some.domain.com").and_return([true, ["1.2.3.4"]])
    subject.validate
    subject.should be_valid
    subject.errors.should == []
  end

  it "fails to resolve invalid DNS -> single IP mapping" do
    subject.should_receive(:resolve_dns).with("some.domain.com").and_return([false, []])
    subject.validate
    subject.should_not be_valid
    subject.errors.should == ["Cannot resolve DNS 'some.domain.com' to an IP address"]
  end

  it "resolves DNS to a different IP" do
    subject.should_receive(:resolve_dns).with("some.domain.com").and_return([true, ["6.6.6.6"]])
    subject.validate
    subject.should_not be_valid
    subject.errors.should == ["DNS 'some.domain.com' resolves to: 6.6.6.6"]
  end
end