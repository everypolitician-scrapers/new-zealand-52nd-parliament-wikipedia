#!/bin/env ruby
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'
require 'wikidata_ids_decorator'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class MembersPage < Scraped::HTML
  decorator WikidataIdsDecorator::Links

  field :members do
    members_tables.xpath('.//tr[td[2]]').map { |tr| fragment(tr => MemberRow).to_h }
  end

  private

  def members_tables
    noko.xpath('//table[.//th[contains(.,"Term in office")]]')
  end
end

class MemberRow < Scraped::HTML
  # Mapping these automatically is too difficult
  PARTIES = {
    'Labour'                              => 'Q1048192',
    'New Zealand First'                   => 'Q180059',
    'Green Party of Aotearoa New Zealand' => 'Q1327761',
    'National'                            => 'Q204716',
    'ACT New Zealand'                     => 'Q288838',
  }.freeze

  field :name do
    tds[2].css('a').map(&:text).map(&:tidy).first
  end

  field :id do
    tds[2].css('a/@wikidata').map(&:text).first
  end

  field :area do
    tds[3].css('a').map(&:text).map(&:tidy).first
  end

  field :area_id do
    tds[3].css('a/@wikidata').map(&:text).first
  end

  field :party do
    noko.xpath('ancestor::table//th').first.text.tidy.sub(/\s\(.*/, '')
  end

  field :party_id do
    PARTIES[party]
  end

  private

  def tds
    noko.css('td')
  end

  def party_header
    noko.xpath('preceding::h3/span[@class="mw-headline"]').last
  end
end

url = 'https://en.wikipedia.org/wiki/52nd_New_Zealand_Parliament'
Scraped::Scraper.new(url => MembersPage).store(:members, index: %i[name party])
