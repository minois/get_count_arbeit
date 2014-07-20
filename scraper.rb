# -*- encoding: utf-8 -*-
# This is a template for a Ruby scraper on Morph (https://morph.io)
#
# == this data scheme ==
#                           |<--           site            -->|
#  | date | prefecture_name | an | mynavi | baitoru | e-aidem | get_time |

require 'scraperwiki'
require 'mechanize'
require 'json'
require 'pp'

URL_AN = 'http://weban.jp/'
URL_MYNAVI = 'http://baito.mynavi.jp/'
URL_MYNAVI_AREA = 'http://baito.mynavi.jp/%s/?json=condition&category=area'
URL_BAITORU = 'http://www.baitoru.com/'
URL_EAIDEM = 'http://www.e-aidem.com/index.htm'
URL_EAIDEM_AREA = 'http://www.e-aidem.com/aps/list.htm?L=BMSList&KCD_=%s'

def main

	start_time = Time.now
	count_table = {}

	puts "getting an..."
	get_count_from_an(count_table)
	puts "get an " + sprintf("%.4fs (%s)", Time.now - start_time, Time.now.strftime("%Y/%m/%d %H:%M:%S"))

	puts "getting mynavi..."
	get_count_from_mynavi(count_table)
	puts "get mynavi " + sprintf("%.4fs (%s)", Time.now - start_time, Time.now.strftime("%Y/%m/%d %H:%M:%S"))

	puts "getting baitoru..."
	get_count_from_baitoru(count_table)
	puts "get baitoru " + sprintf("%.4fs (%s)", Time.now - start_time, Time.now.strftime("%Y/%m/%d %H:%M:%S"))

	puts "getting eaidem..."
	get_count_from_eaidem(count_table)
	puts "get eaidem " + sprintf("%.4fs (%s)", Time.now - start_time, Time.now.strftime("%Y/%m/%d %H:%M:%S"))

#	insert_data(count_table)

end

def get_count_from_an(count_table)
	count = {}
	xpath = ''
	agent = Mechanize.new

	page = agent.get(URL_AN)
	xpath = '//*[@id="gheader"]/div/div[3]/p[2]/span/text()'
	count['全国'] = page.parser.xpath(xpath).to_s

	xpath = '//*[@id="mainContents"]/div[4]/ul/li'
	list = page.parser.xpath(xpath)
	list.each do |li|
		area = li.css('a').text
		/（(\d+)）/ =~ li.text
		count[area] = $1
	end

	count_table['an'] = count
end

def get_count_from_mynavi(count_table)
	count = {}
	xpath = ''
	agent = Mechanize.new

	page = agent.get(URL_MYNAVI)
	xpath = '//*[@id="counterNumber"]/text()'
	count['全国'] = page.parser.xpath(xpath).to_s

	get_mynavi_larea_list().each do |larea|
		url = sprintf(URL_MYNAVI_AREA, larea);
		uri = URI.parse(url)
		json = Net::HTTP.get(uri)
		result = JSON.parse(json)
		
		first = result['panel']['area']['checkboxgroup']['first']
		first[0]['data'].each do |items|
			items.each do |item|
				item.each do |k, v|
					count[v['name']] = v['count'].gsub(/\(|\)|,/, '')
				end
			end
		end
		sleep 0.3
	end

	count_table['mynavi'] = count
end

def get_count_from_baitoru(count_table)
	count = {}
	xpath = ''
	agent = Mechanize.new

	xpath = '//*[@id="js-globalHeader"]/div[2]/div[2]/div[2]/dl[1]/dd/em/text()'
	page = agent.get(URL_BAITORU)
	count['全国'] = page.parser.xpath(xpath).to_s.gsub(/\(|\)|,/, '')

	xpath = '//*[@id="contents"]/div[2]/div[1]/div/div[2]/div/div/div[2]/div/div/div/div[1]/form/div[1]/h3/span/text()'
	get_baitoru_url_list().each do |url, area_name|
		page = agent.get(url)
		count[area_name] = page.parser.xpath(xpath).to_s.gsub(/\(|\)|,/, '')
		sleep 0.3
	end

	count_table['baitoru'] = count
end

def get_count_from_eaidem(count_table)
	count = {}
	xpath = ''
	agent = Mechanize.new

	xpath = '//*[@id="copy"]/dl/dd/text()'
	page = agent.get(URL_EAIDEM)
	count['全国'] = page.parser.xpath(xpath).to_s.gsub(/\(|\)|,/, '')

	xpath = '//span[@id="searchNum"]/text()'
	get_eaidem_kcd_list().each do |cd, name|
		url = sprintf(URL_EAIDEM_AREA, cd)
		page = agent.get(url)
		count[name] = page.parser.xpath(xpath).to_s
		sleep 0.3
	end
	
	count_table['eaidem'] = count
end

def insert_data(count_table)

	day = Time.now
	date = day.strftime("%Y%m%d")
	get_time = day.strftime("%Y%m%d%H%M%S")

	list = get_prefecture_list()
	list.unshift('全国')
	list.each do |prefecture_name|
		ScraperWiki.save_sqlite(
			['date', 'prefecture_name'],
			{
				'date' => date,
				'prefecture_name' => prefecture_name,
				'an' => count_table['an'][prefecture_name],
				'mynavi' => count_table['mynavi'][prefecture_name],
				'baitoru' => count_table['baitoru'][prefecture_name],
				'eaidem' => count_table['eaidem'][prefecture_name],
				'get_time' => get_time
			}
		)
	end

end

def get_mynavi_larea_list
	return [
		'kanto',
		'kansai',
		'tokai',
		'hokkaido',
		'hokuriku',
		'shikoku',
		'kyusyu',
	]
end

def get_prefecture_list
	return [
		'北海道',
		'青森県',
		'岩手県',
		'宮城県',
		'秋田県',
		'山形県',
		'福島県',
		'茨城県',
		'栃木県',
		'群馬県',
		'埼玉県',
		'千葉県',
		'東京都',
		'神奈川県',
		'新潟県',
		'富山県',
		'石川県',
		'福井県',
		'山梨県',
		'長野県',
		'岐阜県',
		'静岡県',
		'愛知県',
		'三重県',
		'滋賀県',
		'京都府',
		'大阪府',
		'兵庫県',
		'奈良県',
		'和歌山県',
		'鳥取県',
		'島根県',
		'岡山県',
		'広島県',
		'山口県',
		'徳島県',
		'香川県',
		'愛媛県',
		'高知県',
		'福岡県',
		'佐賀県',
		'長崎県',
		'熊本県',
		'大分県',
		'宮崎県',
		'鹿児島県',
		'沖縄県',
	]
end

def get_baitoru_url_list
	return {
		'/kanto/area/tokyo' => '東京都',
		'/kanto/area/kanagawa' => '神奈川県',
		'/kanto/area/saitama' => '埼玉県',
		'/kanto/area/chiba' => '千葉県',
		'/kanto/area/tochigi' => '栃木県',
		'/kanto/area/ibaraki' => '茨城県',
		'/kanto/area/gumma' => '群馬県',
		'/tokai/area/aichi' => '愛知県',
		'/tokai/area/gifu' => '岐阜県',
		'/tokai/area/shizuoka' => '静岡県',
		'/tokai/area/mie' => '三重県',
		'/kansai/area/osaka' => '大阪府',
		'/kansai/area/hyogo' => '兵庫県',
		'/kansai/area/kyoto' => '京都府',
		'/kansai/area/shiga' => '滋賀県',
		'/kansai/area/nara' => '奈良県',
		'/kansai/area/wakayama' => '和歌山県',
		'/tohoku/area/hokkaido' => '北海道',
		'/tohoku/area/aomori' => '青森県',
		'/tohoku/area/akita' => '秋田県',
		'/tohoku/area/yamagata' => '山形県',
		'/tohoku/area/iwate' => '岩手県',
		'/tohoku/area/miyagi' => '宮城県',
		'/tohoku/area/fukushima' => '福島県',
		'/koshinetsu/area/nigata' => '新潟県',
		'/koshinetsu/area/yamanashi' => '山梨県',
		'/koshinetsu/area/nagano' => '長野県',
		'/koshinetsu/area/ishikawa' => '石川県',
		'/koshinetsu/area/toyama' => '富山県',
		'/koshinetsu/area/fukui' => '福井県',
		'/chushikoku/area/okayama' => '岡山県',
		'/chushikoku/area/hiroshima' => '広島県',
		'/chushikoku/area/tottori' => '鳥取県',
		'/chushikoku/area/shimane' => '島根県',
		'/chushikoku/area/yamaguchi' => '山口県',
		'/chushikoku/area/kagawa' => '香川県',
		'/chushikoku/area/tokushima' => '徳島県',
		'/chushikoku/area/ehime' => '愛媛県',
		'/chushikoku/area/kochi' => '高知県',
		'/kyushu/area/fukuoka' => '福岡県',
		'/kyushu/area/saga' => '佐賀県',
		'/kyushu/area/nagasaki' => '長崎県',
		'/kyushu/area/kumamoto' => '熊本県',
		'/kyushu/area/oita' => '大分県',
		'/kyushu/area/kagoshima' => '鹿児島県',
		'/kyushu/area/miyazaki' => '宮崎県',
		'/kyushu/area/okinawa' => '沖縄県',
	}
end

def get_eaidem_kcd_list
	return {
		'01' => '北海道',
		'02' => '青森県',
		'03' => '岩手県',
		'04' => '宮城県',
		'05' => '秋田県',
		'06' => '山形県',
		'07' => '福島県',
		'08' => '茨城県',
		'09' => '栃木県',
		'10' => '群馬県',
		'11' => '埼玉県',
		'12' => '千葉県',
		'13' => '東京都',
		'14' => '神奈川県',
		'15' => '新潟県',
		'16' => '富山県',
		'17' => '石川県',
		'18' => '福井県',
		'19' => '山梨県',
		'20' => '長野県',
		'21' => '岐阜県',
		'22' => '静岡県',
		'23' => '愛知県',
		'24' => '三重県',
		'25' => '滋賀県',
		'26' => '京都府',
		'27' => '大阪府',
		'28' => '兵庫県',
		'29' => '奈良県',
		'30' => '和歌山県',
		'31' => '鳥取県',
		'32' => '島根県',
		'33' => '岡山県',
		'34' => '広島県',
		'35' => '山口県',
		'36' => '徳島県',
		'37' => '香川県',
		'38' => '愛媛県',
		'39' => '高知県',
		'40' => '福岡県',
		'41' => '佐賀県',
		'42' => '長崎県',
		'43' => '熊本県',
		'44' => '大分県',
		'45' => '宮崎県',
		'46' => '鹿児島県',
		'47' => '沖縄県',
	}
end

main

# vim:set ts=4 num 
