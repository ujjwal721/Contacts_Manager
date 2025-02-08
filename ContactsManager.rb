require 'json'

# Contact Class
class Contact
  attr_accessor :name, :email, :phone

  def initialize(name, email, phone)
    @name = name
    @email = email
    @phone = phone
  end

  def to_hash
    { name: @name, email: @email, phone: @phone }
  end
end

# Contact Manager Class
class ContactManager
  FILE_PATH = 'contacts.json'

  def initialize
    load_contacts
  end

  def load_contacts
    if File.exist?(FILE_PATH)
      file_content = File.read(FILE_PATH)
      @contacts = file_content.empty? ? [] : JSON.parse(file_content, symbolize_names: true)
    else
      @contacts = []
      save_contacts
    end
  end

  def save_contacts
    File.write(FILE_PATH, JSON.pretty_generate(@contacts))
  end

  # Adds a new contact, using phone as the unique identifier.
  def add_contact(name, email, phone)
    if find_contact(phone)
      puts "❌ A contact with phone number #{phone} already exists."
    else
      contact = Contact.new(name, email, phone)
      @contacts << contact.to_hash
      save_contacts
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

  # Finds a contact by phone number.
  def find_contact(phone)
    @contacts.find { |c| c[:phone] == phone }
  end

  # Updates a contact. Uses the original phone number to locate the contact.
  # Optionally, you can update the phone number to a new one if provided.
  def update_contact(phone, name: nil, email: nil, new_phone: nil)
    contact = find_contact(phone)
    if contact
      contact[:name] = name unless name.nil? || name.strip.empty?
      contact[:email] = email unless email.nil? || email.strip.empty?
      if new_phone && !new_phone.strip.empty?
        # Check if new phone already exists in another contact.
        if find_contact(new_phone)
          puts "❌ A contact with phone number #{new_phone} already exists."
          return
        else
          contact[:phone] = new_phone
        end
      end
      save_contacts
      puts "✅ Contact updated successfully!"
    else
      puts "❌ Contact not found."
    end
  end

  # Deletes a contact using the phone number.
  def delete_contact(phone)
    contact = find_contact(phone)
    if contact
      @contacts.delete(contact)
      save_contacts
      puts "🗑️ Contact deleted successfully!"
    else
      puts "❌ Contact not found."
    end
  end

  # Searches for contacts based on a query in name or email.
  def search_contacts(query)
    results = @contacts.select do |c|
      c[:name].downcase.include?(query.downcase) || c[:email].downcase.include?(query.downcase)
    end
    if results.empty?
      puts "🔍 No matching contacts found."
    else
      puts "\n🔍 Search Results:"
      results.each { |c| puts "Name: #{c[:name]}, Email: #{c[:email]}, Phone: #{c[:phone]}" }
    end
  end
end

# Interactive Menu
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
      print "Enter Phone (unique): "
      phone = gets.chomp
      manager.add_contact(name, email, phone)
    when 2
      manager.list_contacts
    when 3
      print "Enter name or email to search: "
      query = gets.chomp
      manager.search_contacts(query)
    when 4
      print "Enter the Phone number of the contact to update: "
      phone = gets.chomp
      print "Enter New Name (leave blank to keep current): "
      name = gets.chomp
      print "Enter New Email (leave blank to keep current): "
      email = gets.chomp
      print "Enter New Phone (leave blank to keep current): "
      new_phone = gets.chomp
      manager.update_contact(phone, name: name, email: email, new_phone: new_phone)
    when 5
      print "Enter the Phone number of the contact to delete: "
      phone = gets.chomp
      manager.delete_contact(phone)
    when 6
      puts "👋 Exiting... Goodbye!"
      break
    else
      puts "❌ Invalid option. Please try again."
    end
  end
end

main
