require 'json'

# ------------------------------
# Trie Implementation
# ------------------------------

class TrieNode
  attr_accessor :children, :contact_phones

  def initialize
    @children = {}           # Mapping: character => TrieNode
    @contact_phones = []     # List of contact phone numbers associated with this node
  end
end

class Trie
  def initialize
    @root = TrieNode.new
  end

  # Insert a word (suffix) into the trie, associating it with the given contact's phone.
  def insert(word, contact_phone)
    node = @root
    word.each_char do |char|
      node.children[char] ||= TrieNode.new
      node = node.children[char]
      node.contact_phones << contact_phone unless node.contact_phones.include?(contact_phone)
    end
  end

  # Delete the association of contact_phone from the given word (suffix).
  def delete(word, contact_phone)
    delete_helper(@root, word, 0, contact_phone)
  end

  def delete_helper(node, word, index, contact_phone)
    return if node.nil?
    if index == word.length
      node.contact_phones.delete(contact_phone)
    else
      char = word[index]
      if node.children[char]
        delete_helper(node.children[char], word, index + 1, contact_phone)
        if node.children[char].children.empty? && node.children[char].contact_phones.empty?
          node.children.delete(char)
        end
      end
      node.contact_phones.delete(contact_phone)
    end
  end

  # Search the trie for a given prefix and return an array of associated contact phone numbers.
  def search(prefix)
    node = @root
    prefix.each_char do |char|
      return [] unless node.children[char]
      node = node.children[char]
    end
    node.contact_phones
  end
end

# ------------------------------
# Contact Class
# ------------------------------

class Contact
  attr_accessor :name, :email, :phone

  def initialize(name, email, phone)
    @name  = name
    @email = email
    @phone = phone
  end

  def to_hash
    { name: @name, email: @email, phone: @phone }
  end
end

# ------------------------------
# Contact Manager Class (with pre-built Trie, error handling, and data validation)
# ------------------------------

class ContactManager
  FILE_PATH = 'contacts.json'

  def initialize
    load_contacts
    @trie = Trie.new
    build_trie_index
  end

  # Load contacts from the JSON file with error handling.
  def load_contacts
    if File.exist?(FILE_PATH)
      begin
        file_content = File.read(FILE_PATH)
        @contacts = file_content.strip.empty? ? [] : JSON.parse(file_content, symbolize_names: true)
      rescue JSON::ParserError => e
        puts "Error parsing JSON file: #{e.message}"
        @contacts = []
      rescue StandardError => e
        puts "Error reading contacts: #{e.message}"
        @contacts = []
      end
    else
      @contacts = []
      save_contacts
    end
  end

  # Save contacts to the JSON file with error handling.
  def save_contacts
    begin
      File.write(FILE_PATH, JSON.pretty_generate(@contacts))
    rescue StandardError => e
      puts "Error saving contacts: #{e.message}"
    end
  end

  # Helper: Validate that a phone number is exactly 10 digits.
  def valid_phone?(phone)
    !!(phone =~ /\A\d{10}\z/)
  end

  def valid_email?(email)
    !!(email =~ /\A[a-zA-Z0-9._%+-]+@gmail\.com\z/)
  end

  # Build the Trie index for all contacts (called once during initialization).
  def build_trie_index
    @contacts.each { |contact| add_contact_to_trie(contact) }
  end

  # Insert all suffixes of a contact's name and email into the Trie.
  def add_contact_to_trie(contact)
    phone = contact[:phone]
    # Insert suffixes for the name.
    name_text = contact[:name].downcase
    (0...name_text.length).each { |i| @trie.insert(name_text[i..-1], phone) }
    # Insert suffixes for the email.
    email_text = contact[:email].downcase
    (0...email_text.length).each { |i| @trie.insert(email_text[i..-1], phone) }
  end

  # Remove a contact's entries from the Trie.
  def remove_contact_from_trie(contact)
    phone = contact[:phone]
    name_text = contact[:name].downcase
    (0...name_text.length).each { |i| @trie.delete(name_text[i..-1], phone) }
    email_text = contact[:email].downcase
    (0...email_text.length).each { |i| @trie.delete(email_text[i..-1], phone) }
  end

  # Add a new contact; validate phone and update the Trie if successful.
 def add_contact(name, email, phone)
  unless valid_phone?(phone)
    puts "❌ Invalid phone number format. Phone number must be exactly 10 digits."
    return
  end
  unless valid_email?(email)
    puts "❌ Invalid email format. Email must end with '@gmail.com'."
    return
  end
  if find_contact(phone)
    puts "❌ A contact with phone number #{phone} already exists."
  else
    contact = Contact.new(name, email, phone)
    @contacts << contact.to_hash
    save_contacts
    add_contact_to_trie(contact.to_hash)
    puts "✅ Contact added successfully!"
  end
end

  def list_contacts
    if @contacts.empty?
      puts "📂 No contacts available."
    else
      puts "\n📜 Contacts List:"
      @contacts.each { |c| puts "Name: #{c[:name]}, Email: #{c[:email]}, Phone: #{c[:phone]}" }
    end
  end

  # Find a contact by phone number.
  def find_contact(phone)
    @contacts.find { |c| c[:phone] == phone }
  end

  # Find a contact by name (case-insensitive).
  def find_contact_by_name(name)
    @contacts.find { |c| c[:name].downcase == name.downcase }
  end

  # Update a contact by name. Validate new phone if provided.
  def update_contact_by_name(name, new_name: nil, email: nil, new_phone: nil)
    contact = find_contact_by_name(name)
    if contact
      old_contact = contact.dup  # Keep a copy of the old data.
  
      contact[:name] = new_name unless new_name.nil? || new_name.strip.empty?
  
      if email && !email.strip.empty?
        unless valid_email?(email)
          puts "❌ Invalid email format. Email must end with '@gmail.com'."
          return
        end
        contact[:email] = email
      end
  
      if new_phone && !new_phone.strip.empty?
        unless valid_phone?(new_phone)
          puts "❌ Invalid phone number format. Phone number must be exactly 10 digits."
          return
        end
        if new_phone != contact[:phone] && find_contact(new_phone)
          puts "❌ A contact with phone number #{new_phone} already exists."
          return
        else
          contact[:phone] = new_phone
        end
      end
  
      save_contacts
      remove_contact_from_trie(old_contact)
      add_contact_to_trie(contact)
      puts "✅ Contact updated successfully!"
    else
      puts "❌ Contact not found."
    end
  end

  # Delete a contact by name.
  def delete_contact_by_name(name)
    contact = find_contact_by_name(name)
    if contact
      remove_contact_from_trie(contact)
      @contacts.delete(contact)
      save_contacts
      puts "🗑️ Contact deleted successfully!"
    else
      puts "❌ Contact not found."
    end
  end

  # Search contacts using the pre-built Trie for a given query substring.
  def search_contacts(query)
    contact_phones = @trie.search(query.downcase)
    results = @contacts.select { |c| contact_phones.include?(c[:phone]) }
    
    sorted_results = results.sort_by { |c| c[:name].to_s.downcase }
    
    if sorted_results.empty?
      puts "🔍 No matching contacts found."
    else
      puts "\n🔍 Search Results"
      sorted_results.each { |c| puts "Name: #{c[:name]}, Email: #{c[:email]}, Phone: #{c[:phone]}" }
    end
  end
end

# ------------------------------
# Interactive Menu
# ------------------------------

def main
  manager = ContactManager.new

  loop do
    puts "\n📞 Contact Manager"
    puts "1️⃣  Add Contact"
    puts "2️⃣  List Contacts"
    puts "3️⃣  Search Contacts"
    puts "4️⃣  Update Contact"
    puts "5️⃣  Delete Contact"
    puts "6️⃣  Exit"
    print "➡️  Choose an option: "

    choice = gets.chomp.to_i

    case choice
    when 1
      print "Enter Name: "
      name = gets.chomp
      print "Enter Email: "
      email = gets.chomp
      print "Enter Phone: "
      phone = gets.chomp
      manager.add_contact(name, email, phone)
    when 2
      manager.list_contacts
    when 3
      print "Enter the Name of the contact to search: "
      query = gets.chomp
      manager.search_contacts(query)
    when 4
      print "Enter the Name of the contact to update: "
      name = gets.chomp
      print "Enter New Name (leave blank to keep current): "
      new_name = gets.chomp
      print "Enter New Email (leave blank to keep current): "
      email = gets.chomp
      print "Enter New Phone (leave blank to keep current): "
      new_phone = gets.chomp
      manager.update_contact_by_name(name, new_name: new_name, email: email, new_phone: new_phone)
    when 5
      print "Enter the Name of the contact to delete: "
      name = gets.chomp
      manager.delete_contact_by_name(name)
    when 6
      puts "👋 Exiting... Goodbye!"
      break
    else
      puts "❌ Invalid option. Please try again."
    end
  end
end

main
