requires "Algorithm::Permute" => "0";
requires "CHI" => "0";
requires "CLI::Helpers" => "0";
requires "Cache::FastMmap" => "0";
requires "Const::Fast" => "0";
requires "DBIx::Connector" => "0";
requires "Daemon::Daemonize" => "0";
requires "DateTime" => "0";
requires "DateTime::Format::Pg" => "0";
requires "Exception::Class::DBI" => "0";
requires "FindBin" => "0";
requires "Getopt::Long::Descriptive" => "0";
requires "HTML::Entities" => "0";
requires "JSON::MaybeXS" => "0";
requires "LWP::Simple" => "0";
requires "List::Util" => "0";
requires "Log::Dispatch::FileRotate" => "0";
requires "Log::Log4perl" => "0";
requires "Module::Pluggable" => "0";
requires "Mojo::Base" => "0";
requires "Mojolicious::Plugin" => "0";
requires "Mojolicious::Plugin::YamlConfig" => "0";
requires "Moose" => "0";
requires "Moose::Role" => "0";
requires "MooseX::Types" => "0";
requires "MooseX::Types::Moose" => "0";
requires "Net::DNS" => "0";
requires "Net::DNS::Nameserver" => "0";
requires "Net::DNS::Packet" => "0";
requires "Net::DNS::SEC" => "0";
requires "Net::IP" => "0";
requires "Net::Whois::Parser" => "0";
requires "Net::Whois::Raw" => "0";
requires "NetPacket::Ethernet" => "0";
requires "NetPacket::IP" => "0";
requires "NetPacket::IPv6" => "0";
requires "NetPacket::TCP" => "0";
requires "NetPacket::UDP" => "0";
requires "POE" => "0";
requires "POE::Component::Log4perl" => "0";
requires "POE::Component::Pcap" => "0";
requires "POE::Filter::Line" => "0";
requires "POE::Filter::Reference" => "0";
requires "POE::Wheel::ReadWrite" => "0";
requires "POE::Wheel::Run" => "0";
requires "POSIX" => "0";
requires "Path::Tiny" => "0";
requires "Pod::Usage" => "0";
requires "Sys::CpuAffinity" => "0";
requires "Sys::Syslog" => "0";
requires "Text::Soundex" => "0";
requires "Text::Unidecode" => "0";
requires "Tree::DAG_Node" => "0";
requires "YAML" => "0";
requires "base" => "0";
requires "feature" => "0";
requires "namespace::autoclean" => "0";
requires "perl" => "5.010";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::Mojo" => "0";
  requires "Test::More" => "0";
  requires "Test::Perl::Critic" => "0";
  requires "blib" => "1.01";
  requires "perl" => "5.010";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "perl" => "5.010";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::EOL" => "0";
  requires "Test::More" => "0.88";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
};
