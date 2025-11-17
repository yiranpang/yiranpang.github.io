require "active_support/all"
require 'nokogiri'
require 'open-uri'
require 'yaml'

module Helpers
  extend ActiveSupport::NumberHelper
end

module Jekyll
  class GoogleScholarCitationsTag < Liquid::Tag
    Citations = { }
    @@manual_citations = nil

    def initialize(tag_name, params, tokens)
      super
      splitted = params.split(" ").map(&:strip)
      @scholar_id = splitted[0]
      @article_id = splitted[1]

      if @scholar_id.nil? || @scholar_id.empty?
        puts "Invalid scholar_id provided"
      end

      if @article_id.nil? || @article_id.empty?
        puts "Invalid article_id provided"
      end

      # Load manual citations cache once
      if @@manual_citations.nil?
        load_manual_citations
      end
    end

    def load_manual_citations
      begin
        # Get the Jekyll site root directory
        site_root = File.expand_path('../..', __dir__)
        cache_file = File.join(site_root, '_data', 'scholar_citations.yml')
        
        if File.exist?(cache_file)
          @@manual_citations = YAML.load_file(cache_file) || {}
          puts "Loaded manual citations cache with #{@@manual_citations.keys.length} entries"
        else
          @@manual_citations = {}
          puts "No manual citations cache found at #{cache_file}"
        end
      rescue => e
        @@manual_citations = {}
        puts "Error loading manual citations cache: #{e.message}"
      end
    end

    def render(context)
      article_id = context[@article_id.strip]
      scholar_id = context[@scholar_id.strip]
      article_url = "https://scholar.google.com/citations?view_op=view_citation&hl=en&user=#{scholar_id}&citation_for_view=#{scholar_id}:#{article_id}"

      begin
          # If the citation count has already been fetched, return it
          if GoogleScholarCitationsTag::Citations[article_id]
            return GoogleScholarCitationsTag::Citations[article_id]
          end

          # Sleep for a random amount of time to avoid being blocked
          sleep(rand(1.5..3.5))

          # Fetch the article page
          doc = Nokogiri::HTML(URI.open(article_url, "User-Agent" => "Ruby/#{RUBY_VERSION}"))

          # Attempt to extract the "Cited by n" string from the meta tags
          citation_count = 0

          # Look for meta tags with "name" attribute set to "description"
          description_meta = doc.css('meta[name="description"]')
          og_description_meta = doc.css('meta[property="og:description"]')

          if !description_meta.empty?
            cited_by_text = description_meta[0]['content']
            matches = cited_by_text.match(/Cited by (\d+[,\d]*)/)

            if matches
              citation_count = matches[1].sub(",", "").to_i
            end

          elsif !og_description_meta.empty?
            cited_by_text = og_description_meta[0]['content']
            matches = cited_by_text.match(/Cited by (\d+[,\d]*)/)

            if matches
              citation_count = matches[1].sub(",", "").to_i
            end
          end

        citation_count = Helpers.number_to_human(citation_count, :format => '%n%u', :precision => 2, :units => { :thousand => 'K', :million => 'M', :billion => 'B' })

      rescue Exception => e
        # Handle any errors that may occur during fetching
        citation_count = "N/A"

        # Try to use manual citation cache as fallback
        if @@manual_citations && @@manual_citations[article_id]
          manual_count = @@manual_citations[article_id].to_i
          citation_count = Helpers.number_to_human(manual_count, :format => '%n%u', :precision => 2, :units => { :thousand => 'K', :million => 'M', :billion => 'B' })
          puts "Using manual citation count for #{article_id}: #{citation_count} (from cache)"
        else
          puts "Error fetching citation count for #{article_id} in #{article_url}: #{e.class} - #{e.message}"
          puts "No manual citation found in cache for #{article_id}"
        end
      end

      GoogleScholarCitationsTag::Citations[article_id] = citation_count
      return "#{citation_count}"
    end
  end
end

Liquid::Template.register_tag('google_scholar_citations', Jekyll::GoogleScholarCitationsTag)
