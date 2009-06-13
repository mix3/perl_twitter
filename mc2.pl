#!/usr/bin/perl

use strict;
use warnings;
use Jcode;
use Text::MeCab;
use Net::Twitter;

package main;

#--[設定]--#
my $username = ""; # id
my $password = ""; # password
my $file = "/home/username/word.txt"; # マルコフ連鎖作成用文章
my $log = "/home/username/bot_log.txt"; # ログファイル

my @wordlist;
open(IN, $file) or die $!;
  @wordlist = <IN>;
close(IN);

my $word = "";
foreach(@wordlist){
  $word = $word.$_;
}

my $gt = GenText->new($word);
my $hatugen = $gt->gen();

# --[処理]--#
if($hatugen ne ""){
  my $twit = Net::Twitter->new(
      username=>$username,
      password=>$password
  );
  $twit->update(Jcode::convert($hatugen, 'utf-8'));
  print $hatugen, "\n";
  open(OUT, ">> $log") or die $!;
    print OUT $hatugen."\n";
  close(OUT);
}else{
  print "fail\n";
  open(OUT, ">> $log") or die $!;
    print OUT "fail\n";
  close(OUT);
}


{
  package GenText;
  sub new{
    my $this = shift;
    my $m = Text::MeCab->new();
    my $n = $m->parse(shift);

    my %markov = ();
    for(; $n->next->next->next; $n = $n->next){
      my @list = ($n->next->surface, $n->next->next->surface, $n->next->next->next->surface);
      if(!${${$markov{$list[0]}}{$list[1]}}{$list[2]}){
        ${${$markov{$list[0]}}{$list[1]}}{$list[2]} = 0;
      }
      ${${$markov{$list[0]}}{$list[1]}}{$list[2]}++;
    }

    my $self = {
      markov => \%markov,
    };
    return bless $self,$this;
  }

=comment
  sub print{
    my $self = shift;
    print Data::Dumper->Dump([$self->{markov}], ['markov']);
  }
=cut

  sub gen{
    my $self = shift;
    my $word = "";
    my %markov = %{$self->{markov}};

    my $f_key = (sort {rand() <=> 0.5} keys %markov)[0];
    my $s_key = (sort {rand() <=> 0.5} keys %{$markov{$f_key}})[0];
    my $t_key = (sort {rand() <=> 0.5} keys %{${$markov{$f_key}}{$s_key}})[0];

    $word = $f_key.$s_key.$t_key;

    my $count = 0;
    while($t_key ne ('' or '。')){
      $count++;
      $f_key = $s_key;
      $s_key = $t_key;
      $t_key = (sort {rand() <=> 0.5} keys %{${$markov{$f_key}}{$s_key}})[0];

      $word = $word.$t_key;
    }
    if($count > 15){
      $word = "";
    }
    return $word;
  }
}

