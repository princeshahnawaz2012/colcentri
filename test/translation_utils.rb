# use require 'test/translation_utils.rb'

# usage example:
# TranslationUtils.compare_translations("es","en")
# TranslationUtils.compare_translations("es","pt-BR")

module TranslationUtils
  IDENTATION = 4

  # Shows diferences between 2 translations's content
  def self.compare_content(hash1, hash2,depth, info = "")
    # todo doesnt work well yet
    hash1.keys.sort.each do |key|
      if (hash1[key].class == Hash) && (hash2.has_key?(key)) && (hash2[key].class == Hash)
        res = hash1[key].diff(hash2[key])
        depth.times {print " "}
        if res.empty?
          info = print_successfull_key(key, depth, info)
        else
          info = print_failed_key(key, depth, info)
          info = compare_content(hash1[key], hash2[key], depth + TranslationUtils::IDENTATION, info)
        end
      end
    end

    return info
  end

  # Shows diferences between 2 translations's keys
  def self.compare_keys(hash1, hash2, depth, info = "")
    res = true

    hash1.keys.sort.reverse.each do |key|
      if !hash2.has_key?(key)
        res = false
        info = print_failed_key(key, depth, info)
      elsif hash1[key].class == Hash  # if hash2.has_key?(key)
        ok,info = compare_keys(hash1[key],hash2[key],depth + TranslationUtils::IDENTATION, info)
        if ok
          info = print_successfull_key(key, depth, info)
        else
          res = false
          info = print_failed_child_key(key, depth, info)
        end
      end
    end

    return res, info
  end

  def self.compare_translations(l1, l2, content = false)
    path1 = "config/locales/#{l1}.yml"
    path2 = "config/locales/#{l2}.yml"
    trans1 = {}
    trans1 = File.open(path1) {|f| trans1 = YAML.load(f) }
    lang1 = trans1.keys.first

    trans2 = {}
    trans2 = File.open(path2) {|f| trans2 = YAML.load(f) }
    lang2 = trans2.keys.first

    puts "Comparing #{lang1} y #{lang2}"

    if trans1[lang1].keys != trans2[lang2].keys
      puts "First level keys doesn't match!!"
      puts "Missing in #{lang1}:"
      puts trans2[lang2].keys - trans1[lang1].keys

      puts "Missing in #{lang2}:"
      puts trans1[lang1].keys - trans2[lang2].keys
    else
      puts "First level keys: passed!"
    end

    puts "-----"
    if content # dont work well yet
      puts "Comparing content:"
      puts compare_content(trans1[lang1],trans2[lang2],TranslationUtils::IDENTATION)
      puts "This function doesnt work properly yet"
    else
      puts "Comparing other keys:"
      ok, info = compare_keys(trans1[lang1],trans2[lang2],TranslationUtils::IDENTATION)
      puts info
      if ok
        puts "Successful!"
      else
        puts "Failed!"
      end
    end
  end


  private

  def self.print_failed_key(key, depth, info = "")
    res = ""
    depth.times { res += " "}
    res = res + "#{key}... failed"
    return res = res + "\n" + info
  end

  def self.print_failed_child_key(key, depth, info = "")
    res = ""
    depth.times { res += " "}
    res = res + "#{key}..."
    return res = res + "\n" + info
  end

  def self.print_successfull_key(key, depth, info = "")
    res = ""
    if depth <=TranslationUtils::IDENTATION
      depth.times { res += " "}
      res += "#{key}... OK"
      res = res + "\n" + info
    else
      res = info
    end
    return res
  end
end

