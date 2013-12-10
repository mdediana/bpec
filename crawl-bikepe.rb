#!/usr/bin/env ruby
#encoding: utf-8

require 'nokogiri'
require 'open-uri'
require 'retryable'

BASE_URL = 'http://ww2.mobilicidade.com.br/bikepe/mapaestacao.asp'
PERIOD   = 5 * 60
HEADER   =
'lat;long;icon;nome;id;status.online;status.operacao;vagas.ocup;num.bici;end'

STDOUT.sync = true

def get_html
  retryable(tries: 3, sleep: 5) do
    html = Nokogiri::HTML(open("#{BASE_URL}"), nil, 'ISO-8859-1')
    html.to_s.encode('UTF-8')
  end
end

def as_csv(html)
  data = []
  html.each_line do |l|
    l.chop!
    data << l if l.start_with?('exibirEstacaMapa(') .. l.end_with?(');')
  end

  data = data.map { |r| r.sub(/exibirEstacaMapa/, '')
                         .delete('"()') }
  rows = data.join.split(';')
  rows.map { |r| r.gsub(/,/, ';') }
end

puts HEADER
while
  t = Time.now.utc.strftime('%Y%m%d%H%M%S')
  as_csv(get_html).each { |r| puts "#{t};#{r}" }

  sleep(PERIOD)
end

#  retryable(:tries => 5, :sleep => 30) do # não para em problema temporário de conexão
