#!/usr/bin/env ruby
# encoding: utf-8

require 'nokogiri'
require 'open-uri'
require 'yaml'
require 'fileutils'

class CitationUpdater
  def initialize
    @root_dir = File.expand_path('..', __dir__)
    @cache_file = File.join(@root_dir, '_data', 'scholar_citations.yml')
    @bib_file = File.join(@root_dir, '_bibliography', 'papers.bib')
    @socials_file = File.join(@root_dir, '_data', 'socials.yml')
    
    @scholar_id = load_scholar_id
    @existing_cache = load_existing_cache
    @updated_count = 0
    @failed_count = 0
  end

  def run
    puts "=" * 60
    puts "Google Scholar Citation Updater"
    puts "=" * 60
    puts ""
    
    if @scholar_id.nil? || @scholar_id.empty?
      puts "❌ Error: Could not find scholar_userid in _data/socials.yml"
      puts "Please add your Google Scholar user ID to _data/socials.yml:"
      puts "  scholar_userid: YOUR_SCHOLAR_ID"
      exit 1
    end
    
    puts "📚 Scholar ID: #{@scholar_id}"
    puts "📁 Cache file: #{@cache_file}"
    puts ""
    
    article_ids = extract_article_ids
    
    if article_ids.empty?
      puts "⚠️  No article IDs found in #{@bib_file}"
      puts "Please make sure your BibTeX entries have 'google_scholar_id' fields."
      exit 0
    end
    
    puts "Found #{article_ids.length} article(s) to update"
    puts ""
    
    article_ids.each_with_index do |article_id, index|
      update_citation(article_id, index + 1, article_ids.length)
    end
    
    save_cache
    print_summary
  end

  private

  def load_scholar_id
    return nil unless File.exist?(@socials_file)
    
    socials = YAML.load_file(@socials_file)
    socials['scholar_userid']
  rescue => e
    puts "⚠️  Warning: Error reading _data/socials.yml: #{e.message}"
    nil
  end

  def load_existing_cache
    return {} unless File.exist?(@cache_file)
    
    YAML.load_file(@cache_file) || {}
  rescue => e
    puts "⚠️  Warning: Error reading existing cache: #{e.message}"
    {}
  end

  def extract_article_ids
    return [] unless File.exist?(@bib_file)
    
    article_ids = []
    content = File.read(@bib_file)
    
    # Extract google_scholar_id from BibTeX entries
    content.scan(/google_scholar_id\s*=\s*[{"]([^}"]+)[}"]/) do |match|
      article_ids << match[0]
    end
    
    article_ids.uniq
  rescue => e
    puts "❌ Error reading bibliography: #{e.message}"
    []
  end

  def update_citation(article_id, current, total)
    print "[#{current}/#{total}] Fetching #{article_id}... "
    
    # Check if we already have this in cache
    if @existing_cache[article_id] && !force_update?
      puts "✓ (cached: #{@existing_cache[article_id]})"
      return
    end
    
    begin
      article_url = "https://scholar.google.com/citations?view_op=view_citation&hl=en&user=#{@scholar_id}&citation_for_view=#{@scholar_id}:#{article_id}"
      
      # Random delay to avoid being blocked
      sleep(rand(2.0..4.0))
      
      # Fetch the page
      doc = Nokogiri::HTML(URI.open(article_url, "User-Agent" => "Mozilla/5.0 (compatible; CitationBot/1.0)"))
      
      # Extract citation count
      citation_count = extract_citation_count(doc)
      
      if citation_count > 0
        @existing_cache[article_id] = citation_count
        puts "✓ #{citation_count} citations"
        @updated_count += 1
      elsif citation_count == 0
        @existing_cache[article_id] = 0
        puts "✓ 0 citations"
        @updated_count += 1
      else
        puts "⚠️  Not found"
        @failed_count += 1
      end
      
    rescue => e
      puts "❌ Error: #{e.message}"
      @failed_count += 1
    end
  end

  def extract_citation_count(doc)
    # Try meta description tags
    description_meta = doc.css('meta[name="description"]')
    og_description_meta = doc.css('meta[property="og:description"]')
    
    if !description_meta.empty?
      cited_by_text = description_meta[0]['content']
      matches = cited_by_text.match(/Cited by (\d+[,\d]*)/)
      return matches[1].gsub(',', '').to_i if matches
    end
    
    if !og_description_meta.empty?
      cited_by_text = og_description_meta[0]['content']
      matches = cited_by_text.match(/Cited by (\d+[,\d]*)/)
      return matches[1].gsub(',', '').to_i if matches
    end
    
    # Try to find "Cited by" link in the page
    cited_by_link = doc.css('a').find { |a| a.text.include?('Cited by') }
    if cited_by_link
      matches = cited_by_link.text.match(/Cited by (\d+[,\d]*)/)
      return matches[1].gsub(',', '').to_i if matches
    end
    
    # Return 0 if no citations found, -1 if error
    0
  end

  def save_cache
    # Sort by article_id for better readability
    sorted_cache = @existing_cache.sort.to_h
    
    # Create backup of existing file
    if File.exist?(@cache_file)
      backup_file = "#{@cache_file}.backup"
      FileUtils.cp(@cache_file, backup_file)
    end
    
    # Write header and data
    File.open(@cache_file, 'w') do |file|
      file.puts "# 手动维护的 Google Scholar 引用数缓存"
      file.puts "# 格式: article_id: citation_count"
      file.puts "#"
      file.puts "# 使用说明:"
      file.puts "# 1. 访问 Google Scholar 个人主页获取文章的引用数"
      file.puts "# 2. article_id 可以从文献的 BibTeX 或 Google Scholar URL 中获取"
      file.puts "# 3. citation_count 直接填写数字即可（不需要 K/M 等单位，程序会自动格式化）"
      file.puts "#"
      file.puts "# 最后更新: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
      file.puts ""
      
      sorted_cache.each do |article_id, count|
        file.puts "#{article_id}: #{count}"
      end
    end
    
    puts ""
    puts "💾 Cache file updated: #{@cache_file}"
  end

  def print_summary
    puts ""
    puts "=" * 60
    puts "Summary"
    puts "=" * 60
    puts "✓ Successfully updated: #{@updated_count}"
    puts "❌ Failed: #{@failed_count}" if @failed_count > 0
    puts "📊 Total entries in cache: #{@existing_cache.length}"
    puts ""
    
    if @updated_count > 0
      puts "✨ Done! Your citation cache has been updated."
      puts "   Run 'bundle exec jekyll serve' to see the changes."
    end
  end

  def force_update?
    ARGV.include?('--force') || ARGV.include?('-f')
  end
end

# Run the updater
if __FILE__ == $0
  updater = CitationUpdater.new
  updater.run
end
