# https://wiki.apache.org/spamassassin/ClamAVPlugin
package ClamAV;
use strict;

# version 2.0, 2010-01-07
#   - use SA public interface set_tag() and add_header, instead of
#     pushing a header field directly into $conf->{headers_spam}

# our $CLAMD_SOCK = 3310;               # for TCP-based usage
our $CLAMD_SOCK = "/var/lib/clamav/clamd.sock";   # change me

use Mail::SpamAssassin;
use Mail::SpamAssassin::Plugin;
use Mail::SpamAssassin::Logger;
use File::Scan::ClamAV;
our @ISA = qw(Mail::SpamAssassin::Plugin);

sub new {
  my ($class, $mailsa) = @_;
  $class = ref($class) || $class;
  my $self = $class->SUPER::new($mailsa);
  bless($self, $class);
  $self->register_eval_rule("check_clamav");
  return $self;
}

sub check_clamav {
  my($self, $pms, $fulltext) = @_;
  dbg("ClamAV: invoking File::Scan::ClamAV, port/socket: %s", $CLAMD_SOCK);
  my $clamav = new File::Scan::ClamAV(port => $CLAMD_SOCK);
  my($code, $virus) = $clamav->streamscan(${$fulltext});
  my $isspam = 0;
  my $header = "";
  if (!$code) {
    my $errstr = $clamav->errstr();
    $header = "Error ($errstr)";
  } elsif ($code eq 'OK') {
    $header = "No";
  } elsif ($code eq 'FOUND') {
    $header = "Yes ($virus)";
    $isspam = 1;
    # include the virus name in SpamAssassin's report
    $pms->test_log($virus);
  } else {
    $header = "Error (Unknown return code from ClamAV: $code)";
  }
  dbg("ClamAV: result - $header");
  $pms->set_tag('CLAMAVRESULT', $header);
  # add a metadatum so that rules can match against the result too
  $pms->{msg}->put_metadata('X-Spam-Virus',$header);
  return $isspam;
}

1;
