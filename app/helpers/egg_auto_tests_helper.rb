module EggAutoTestsHelper
  def response_ajax_auto_egg(text, time = 3000)
    respond_to do |format|
      format.js {render :js => "open_modal(#{text.inspect}, #{time.inspect}); kill_listener_egg();"}
    end
  end

  def end_test_egg(log_file_name, startTime = false)
    begin
      endTime = Time.now
      puts_time_egg(startTime, endTime) if startTime
    rescue Exception => msg
      send_to_log_egg("Ошибка! #{msg}", "Ошибка! #{msg}")
    ensure
      $log_egg.close if !$log_egg.nil?
      until $browser_egg[:message].empty? && $browser_egg[:event].empty?
        sleep 0.5
      end
      respond_to do |format|
        format.js { render :js => "kill_listener_egg(); download_link_egg('#{log_file_name}')" }
      end
    end
  end

  def send_to_amq_and_receive_egg(manager, xml, ignore_ticket = false) # Отправка сообщений в Active MQ по протоколу OpenWire
    java_import 'org.apache.activemq.ActiveMQConnectionFactory'
    java_import 'javax.jms.Session'
    java_import 'javax.jms.TextMessage'
    puts 'Sending message to AMQ (OpenWire)'
    begin
      factory = ActiveMQConnectionFactory.new
      send_to_log_egg("Отправляем XML по адресу: Хост:#{manager.host}, Порт:#{manager.port}, Логин:#{manager.user}, Пароль:#{manager.password}, Очередь:#{manager.queue_out}")
      factory.setBrokerURL("tcp://#{manager.host}:#{manager.port}")
      manager.user.nil? ? user ='' : user=manager.user
      manager.password.nil? ? password ='' : password=manager.user
      connection = factory.createQueueConnection(user, password)
      session = connection.createSession(false, Session.AUTO_ACKNOWLEDGE);
      textMessage = session.createTextMessage(xml.xml_text)
      textMessage.setJMSCorrelationID(SecureRandom.uuid)
      sender = session.createSender(session.createQueue(manager.queue_out))
      connection.start
      connection.destroyDestination(session.createQueue(manager.queue_in)) # Удаляем очередь.
      sender.send(textMessage)
      send_to_log_egg("Отправили сообщение в eGG:\n #{textMessage.getText}", "Отправили сообщение в eGG")
      receiver = session.createReceiver(session.createQueue(manager.queue_in))
      count = 40
      xml_actual = receiver.receive(1000)
      while xml_actual.nil?
        xml_actual = receiver.receive(1000)
        puts count -=1
        return nil if count == 0
      end
      if ignore_ticket
        send_to_log_egg("Получили промежуточный квиток из очереди #{manager.queue_in}:\n #{xml_actual.getText}", "Получили промежуточный квиток от eGG")
        count = 40
        xml_actual = receiver.receive(1000)
        while xml_actual.nil?
          xml_actual = receiver.receive(1000)
          puts count -=1
          return nil if count == 0
        end
      end
      send_to_log_egg("Получили ответ от eGG из очереди #{manager.queue_in}:\n #{xml_actual.getText}", "Получили ответ от eGG")
      return xml_actual.getText
    rescue Exception => msg
      send_to_log_egg("Ошибка! #{msg.backtrace.join("\n")}")
      return nil
    ensure
      sender.close if sender
      receiver.close if receiver
      session.close if session
      connection.close if connection
    end
  end

  def send_to_amq_egg(manager, xml, queue = manager.queue_out) # Отправка сообщений в Active MQ по протоколу OpenWire
    java_import 'org.apache.activemq.ActiveMQConnectionFactory'
    java_import 'javax.jms.Session'
    java_import 'javax.jms.TextMessage'
    puts 'Sending message to AMQ (OpenWire)'
    begin
      factory = ActiveMQConnectionFactory.new
      send_to_log_egg("Отправляем XML по адресу: Хост:#{manager.host}, Порт:#{manager.port}, Логин:#{manager.user}, Пароль:#{manager.password}, Очередь:#{queue}")
      factory.setBrokerURL("tcp://#{manager.host}:#{manager.port}")
      manager.user.nil? ? user ='' : user=manager.user
      manager.password.nil? ? password ='' : password=manager.user
      connection = factory.createQueueConnection(user, password)
      session = connection.createSession(false, Session.AUTO_ACKNOWLEDGE);
      if xml.is_a? String
        textMessage = session.createTextMessage(xml)
      else
        textMessage = session.createTextMessage(xml.xml_text)
      end
      textMessage.setJMSCorrelationID(SecureRandom.uuid)
      sender = session.createSender(session.createQueue(queue))
      connection.start
      connection.destroyDestination(session.createQueue(manager.queue_in)) # Удаляем очередь.
      sender.send(textMessage)
      send_to_log_egg("Отправили сообщение в eGG:\n #{textMessage.getText}", "Отправили сообщение в eGG")
    rescue Exception => msg
      send_to_log_egg("Ошибка! #{msg}")
      return nil
    ensure
      sender.close if sender
      session.close if session
      connection.close if connection
    end
  end

  def receive_from_amq_egg(manager, ignore_ticket = false) # Отправка сообщений в Active MQ по протоколу OpenWire
    java_import 'org.apache.activemq.ActiveMQConnectionFactory'
    java_import 'javax.jms.Session'
    java_import 'javax.jms.TextMessage'
    puts 'Sending message to AMQ (OpenWire)'
    begin
      factory = ActiveMQConnectionFactory.new
      send_to_log_egg("Получаем XML из менеджера: Хост:#{manager.host}, Порт:#{manager.port}, Логин:#{manager.user}, Пароль:#{manager.password}")
      factory.setBrokerURL("tcp://#{manager.host}:#{manager.port}")
      manager.user.nil? ? user ='' : user=manager.user
      manager.password.nil? ? password ='' : password=manager.user
      connection = factory.createQueueConnection(user, password)
      session = connection.createSession(false, Session.AUTO_ACKNOWLEDGE);
      connection.start
      receiver = session.createReceiver(session.createQueue(manager.queue_in))
      count = 40
      xml_actual = receiver.receive(1000)
      while xml_actual.nil?
        xml_actual = receiver.receive(1000)
        puts count -=1
        return nil if count == 0
      end
      if ignore_ticket
        send_to_log_egg("Получили промежуточный квиток из очереди #{manager.queue_in}:\n #{xml_actual.getText}", "Получили промежуточный квиток от eGG")
        count = 40
        xml_actual = receiver.receive(1000)
        while xml_actual.nil?
          xml_actual = receiver.receive(1000)
          puts count -=1
          response_ajax("Ответ не был получен!") and return if count == 0
        end
      end
      send_to_log_egg("Получили ответ от eGG из очереди #{manager.queue_in}:\n #{xml_actual.getText}", "Получили ответ от eGG")
      return xml_actual.getText
    rescue Exception => msg
      send_to_log_egg("Ошибка! #{msg}")
      return nil
    ensure
      receiver.close if receiver
      session.close if session
      connection.close if connection
    end
  end

  def send_to_log_egg(to_log, to_browser = false)
    if to_browser
      if to_browser.include?('--')
        $browser_egg[:message] += "#{to_browser}\n"
      else
        $browser_egg[:message] += "[#{Time.now.strftime('%H:%M:%S')}]: #{to_browser}\n"
      end
    end
    if to_log
      if to_log.include?('Ошибка')
        $log_egg.error(to_log)
      else
        $log_egg.info(to_log)
      end
    end
  end
  def colorize_egg(egg_version, functional, color)
    $browser_egg[:event] = 'colorize_egg'
    $browser_egg[:egg_version] = egg_version
    $browser_egg[:functional] = functional
    $browser_egg[:color] = color
  end
  def puts_line_egg
    return '--'*40
  end
  def puts_time_egg(startTime, endTime)
    dif = (endTime-startTime).to_i.abs
    min = dif/1.minutes
    send_to_log_egg("Завершили проверку за: #{min} мин, #{dif-(min*1.minutes)} сек", "Завершили проверку за: #{min} мин, #{dif-(min*1.minutes)} сек")
  end

  def dir_empty_egg?(egg_dir)
    begin
      send_to_log_egg("Проверка наличия каталога '#{egg_dir}'", "Проверка наличия каталога '#{egg_dir}'")
      sleep 0.5
      if Dir.entries("#{egg_dir}").size <= 2
        send_to_log_egg("Ошибка! Каталог '#{egg_dir}' пустой", "Ошибка! Каталог '#{egg_dir}' пустой")
        return true
      else
        send_to_log_egg("Done! Каталог #{egg_dir} найден и не пустой", "Done! Каталог #{egg_dir} найден и не пустой")
        return false
      end
    rescue Exception
      send_to_log_egg("Ошибка! Каталог '#{egg_dir}' не найден", "Ошибка! Каталог '#{egg_dir}' не найден")
      return true
    end
  end

  def delete_db_egg
    java_import 'oracle.jdbc.OracleDriver'
    java_import 'java.sql.DriverManager'
    begin
      send_to_log_egg("Удаляем БД 'egg_autotest'", "Удаляем БД 'egg_autotest'")
      url = "jdbc:oracle:thin:@vm-corint:1521:corint"
      connection = java.sql.DriverManager.getConnection(url, "sys as sysdba", "waaaaa");
      stmt = connection.create_statement
      stmt.executeUpdate("drop user egg_autotest cascade")
    rescue Exception => msg
      send_to_log_egg("Ошибка! #{msg}", "Ошибка! #{msg}")
      return true
    ensure
      stmt.close
      connection.close
    end
    sleep 0.5
    send_to_log_egg("Done! Удалили тестовую БД.", "Done! Удалили тестовую БД.")
  end

  def start_servicemix_egg(dir)
    send_to_log_egg("Запускаем Servicemix...", "Запускаем Servicemix...")
    begin
      Dir.chdir "#{dir}\\apache-servicemix-6.1.2\\bin"
      startcrypt = "#{dir}\\apache-servicemix-6.1.2\\bin\\startcrypt.bat"
      @servicemix_start_thread_egg = Thread.new do
        Open3.popen3(startcrypt) do | input, output, error, wait_thr |
          input.sync = true
          output.sync = true
          input.puts "admin"
          input.close
          # Thread.new do
          #   puts wait_thr.pid
          #   Thread.current.kill
          # end
          # Process.kill("KILL",wait_thr.pid)
          puts output.readlines do |line|
            puts line
          end
        end
      end
    rescue Exception => msg
      send_to_log_egg("Ошибка! #{msg}", "Ошибка! #{msg}")
      stop_servicemix_egg
    end
  end

  def stop_servicemix_egg(dir = false)
    send_to_log_egg("Останавливаем Servicemix...", "Останавливаем Servicemix...")
    Dir.chdir "#{dir}\\apache-servicemix-6.1.2\\bin"
    @servicemix_stop_thread_egg = Thread.new do
      sleep 1
      system('servicemix.bat stop')
    end
    sleep 3
    @kill_cmd_thread_egg = Thread.new do
      system('Taskkill /IM cmd.exe /F')
    end
    while @servicemix_start_thread_egg.alive?
      puts "@@servicemix_start_thread_egg alive!"
      if @servicemix_stop_thread_egg.alive?
        puts "@@servicemix_stop_thread_egg alive!"
        sleep 0.5
      end
      if @kill_cmd_thread_egg.alive?
        puts "@@kill_cmd_thread_egg alive!"
        sleep 0.5
      end
      sleep 1
    end
    send_to_log_egg("Done! Остановили Servicemix...", "Done! Остановили Servicemix...")
  end
  def ping_server_egg(host)
    begin
      uri = URI.parse(host)
      response = Net::HTTP.get_response(uri)
      puts response.code
      return true if response.code == '200' || '401'
    rescue Errno::ECONNREFUSED
      return false
    end
  end
  def get_decode_answer(xml)
    response = Document.new(xml)
    answer = response.elements['//mq:Answer'].text
    answer_decode = Base64.decode64(answer)
    answer_decode = answer_decode.force_encoding("utf-8")
    send_to_log_egg("Расшифрованный тег Answer:\n#{answer_decode}", "Расшифровали ответ!")
    return answer_decode
  end
  def validate_egg_xml(xsd, xml)
    begin
      send_to_log_egg("Валидируем XML:\n#{xml}\nПо XSD: #{xsd}")
      xsd = Nokogiri::XML::Schema(File.read(xsd))
      xml = Nokogiri::XML(xml)
      result = xsd.validate(xml)
      if result.any?
        send_to_log_egg("Валидация не пройдена! \n#{result.join('<br/>')}", "Валидация не пройдена!")
        return false
      else
        send_to_log_egg("Валидация прошла успешно", "Валидация прошла успешно")
        return true
      end
    rescue Exception => msg
      send_to_log_egg("Ошибка! #{msg}\n#{msg.backtrace.join("\n")}", "Ошибка! #{msg}")
    end
  end
  def ufebs_file_count(packetepd = false)
    dir = 'C:/data/inbox/1/inbound/all'
    code_adps000 = 'ADPS000'
    code_adps001 = 'ADPS001'
    adps000_count = 0
    adps001_count = 0
    count = 50
    packetepd ? positive_code = 3 : positive_code = 1
    send_to_log_egg("packetepd: #{positive_code}")
    until adps001_count == positive_code or count == 0
      if File.directory?(dir)
        Dir.entries(dir).each_entry do |entry|
          adps001_count += 1 if entry.include?(code_adps001)
        end
        puts "Wait ufebs answer..."
      end
      sleep 1
      count -=1
    end
    adps001_count = 0
    if File.directory?(dir)
      send_to_log_egg("Получили ответ из каталога #{dir}", "Получили ответ из каталога #{dir}")
      Dir.entries(dir).each_entry do |entry|
        send_to_log_egg("Файлы в каталоге: #{entry}")
        if entry.include?(code_adps000)
          adps000_count += 1
        elsif entry.include?(code_adps001)
          adps001_count += 1
        elsif entry != '.' && entry != '..'
          filepath = "#{dir}/#{entry}"
          send_to_log_egg("Путь файла: #{filepath}")
          file = File.open(filepath, 'r'){ |file| file.read }
          send_to_log_egg("Получили неожиданный статус \n#{file}", "Получили неожиданный статус #{entry}")
        end
      end
    end
    return adps000_count, adps001_count
  end
end
