class FeedPage
  extend ActiveSupport::Concern

  attr_reader :type, :title, :feeds

  def initialize(type, title, content = nil)
    @type = type
    @title = title
    @content = content

    _parse
  end

  def download_from_web!
    @content = NetModule.download_with_get(_build_url)

    _parse
  end

  def download_from_s3!
    @content = NetModule.get_s3_object(NetModule.get_s3_bucket, _build_s3_path)

    _parse
  end

  def valid?
    ((not @type.nil?) \
      && (not @title.nil?) \
      && (not @feeds.nil?))
  end

  def save!
    if not valid?
      raise "Invalid"
    end

    NetModule.put_s3_object(NetModule.get_s3_bucket, _build_s3_path, @content)
  end

  private

  def _parse
    if @content.nil?
      return nil
    end

    doc = Nokogiri::HTML.parse(@content, nil, "UTF-8")

    title = nil
    doc.xpath("//h1[@class='page_title']") do |h1|
      title = h1.text.strip
    end

    raise "title not match" if @title != title

    @feeds = doc.xpath("//div[@class='item_status']").map do |div|
      feed = {}

      div.xpath("span[contains(@class, 'link_num')]").each do |span|
        feed[:comment_number] = span.text.strip.to_i
      end

      div.xpath("div[@class='item_title']/a").each do |a|
        feed[:path] = a[:href]
        feed[:title] = a.text.strip
      end

      feed
    end
  end

  def _build_url
    "http://ceron.jp/#{@type}/"
  end

  def _build_s3_path
    Settings.s3.folder + "/#{@type}/#{@type}.html"
  end

end