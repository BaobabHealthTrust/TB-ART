class Location < ActiveRecord::Base
  set_table_name "location"
  set_primary_key "location_id"
  include Openmrs

  cattr_accessor :current_location

  def site_id
    Location.current_health_center.description.match(/\(ID=(\d+)\)/)[1] 
  rescue 
    raise "The id for this location has not been set (#{Location.current_location.name}, #{Location.current_location.id})"   
  end

  # Looks for the most commonly used element in the database and sorts the results based on the first part of the string
  def self.most_common_program_locations(search)
    return (self.find_by_sql([
      "SELECT DISTINCT location.name AS name, location.location_id AS location_id \
       FROM location \
       INNER JOIN patient_program ON patient_program.location_id = location.location_id AND patient_program.voided = 0 \
       WHERE location.retired = 0 AND name LIKE ? \
       GROUP BY patient_program.location_id \
       ORDER BY INSTR(name, ?) ASC, COUNT(name) DESC, name ASC \
       LIMIT 10", 
       "%#{search}%","#{search}"]) + [self.current_health_center]).uniq
  end

  def children
    return [] if self.name.match(/ - /)
    Location.find(:all, :conditions => ["name LIKE ?","%" + self.name + " - %"])
  end

  def parent
    return nil unless self.name.match(/(.*) - /)
    Location.find_by_name($1)
  end

  def site_name
    self.name.gsub(/ -.*/,"")
  end

  def related_locations_including_self
    if self.parent
      return self.parent.children + [self]
    else
      return self.children + [self]
    end
  end

  def related_to_location?(location)
    self.site_name == location.site_name
  end

  def self.current_health_center
    @@current_health_center ||= Location.find(GlobalProperty.find_by_property("current_health_center_id").property_value) rescue self.current_location
  end

  def self.current_arv_code
    current_health_center.neighborhood_cell rescue nil
  end
  
  def self.areas
    return @@areas
  end

  def self.current_residences
    return @@current_residences
  end
  
  def self.districts
    return @@districts
  end
  
  def self.tas
    return @@tas
  end
  
  def self.health_facilities
    return @@health_facilities
  end
  
  def self.initialize_areas
    areas = <<EOF
Area 1
Area 10
Area 11
Area 12
Area 13
Area 14
Area 15
Area 16
Area 17
Area 18
Area 18A
Area 18B
Area 19
Area 2
Area 20
Area 21
Area 22
Area 22B
Area 23
Area 24
Area 25
Area 25A
Area 25B
Area 25C
Area 26
Area 27
Area 28
Area 29
Area 3
Area 30
Area 31
Area 32
Area 33
Area 34
Area 35
Area 36
Area 37
Area 38
Area 39
Area 4
Area 40
Area 41
Area 42
Area 43
Area 44
Area 45
Area 46
Area 47
Area 48
Area 49
Area 5
Area 50
Area 51
Area 52
Area 53
Area 54
Area 55
Area 56
Area 57
Area 58
Area 6
Area 7
Area 8
Area 9
EOF
    return areas.split("\n")
  end

  def self.initialize_current_residences
    locations = <<EOF
Air Wing
Bagdad
Balaka
Balaka District
Balaka Town
Baloni Estate
Bambvi
Bango
Bangwe
Bangwe Ward
Baron Mbabvi
Bembeke
Bisayi
Biwi
Blantyre
Blantyre Central Ward
Blantyre City
Blantyre East Ward
Blantyre Rural
Blantyre West Ward
Bondo
Bowa
Bua
Buli
Buluzi
Bunda
Buwa
Bvumbwe
Bwaila
Bwalolanjobvu
Bwatalika
Bwemba
CCDC
Chaalendewa
Chadika
Chadza
Chagogo
Chaima
Chakakala
Chakhaza
Chakhoma
Chakhumbira
chalendewa
Chamadenga
Chambo
Chambwe
Chamchere
Chamkoma
Champhira
Champiti
Chanchele
Changata
Chang'ombe
Chankhandwe
Chankhungu
Chankoma
Chapananga
Chapata
Chaseta
Chatata
Chatsika
Chauma
Chawala
Chaweza
Chawombwa
Chazuma
Chembe
Chibade
Chibanja
Chibanja Ward
Chibungo
Chichiri
Chichiri Ward
Chidothi
Chidzala
Chidzenje
Chigaru
Chigoneka
Chigonthi
Chigumula
Chigumula Ward
Chigwenembe
Chigwilizano
Chigwirizano
Chiimba
Chikanda
Chikandwe
Chikanga
Chikhawo
Chikho
Chikhutu
Chikowa
Chikowi
Chikulamayembe
Chikumbu
Chikungu
Chikuse
Chikwawa
Chikwawa Boma
Chikwawa District
Chikweo
Chikwera
Chiladzulu
Chilambula
Chilanga
Chileka
Chilembwe
Chilikhanda
Chilikumwendo
Chilima
Chilinde
Chilinde 1
Chilinde 2
Chilindemchombo
Chilinza
Chilipansi
Chiloa
Chilobwe
Chilomoni
Chilomoni Ward
Chilooko
Chilowa
Chilowamatambe
Chilutsi
Chiluzi
Chimaliro
Chimango
Chimbalanga
Chimbalani
Chimbayo
Chimbiya
Chimenya
Chimeza
Chimgonera
Chimkombelo
Chimkombero
Chimlozi  Ta Chimutu
Chimoka
Chimombo
Chimphango
Chimphangu
Chimphwafu
Chimphwanya
Chimutu
Chimwala
Chimwamadzi
Chimwaza
Chinangwa
Chindi
Chingala
Chin'gombe
Chinguwo
Chingwirizano
Chinkhadze
Chinkhalamba
Chinkhoma
Chinkhota
Chinkhowe
Chinkhuti
Chinkombelo
Chinkombero
Chinoko
Chinsapo
Chinsapo 1
Chinsapo 2
Chintheche
Chinyama
Chioko
Chiowa
Chioza
Chipala
Chipasula
Chipeni
Chipezaani
Chiphangu
Chipoka
Chipoka Urban
Chiponde
Chiputu
Chiputula
Chiputula Ward
Chiradzulu
Chiradzulu Boma
Chiradzulu District
Chisaleka
Chisamba
Chisapo
Chisapo 1
Chisapo 2
Chiseka
Chisemphere
Chisenga
Chisiyo
Chisuzi
Chitedze
Chitekwele
Chitekwere
Chitera
Chithembwe
Chithetche
Chithope
Chitipa
Chitipa Boma
Chitipa District
Chitipi
Chitukula
Chiuzira
Chiwabvi
Chiwala
Chiwamba
Chiwanja
Chiwe
Chiwere
Chiweza
Chiwoko
Chiwowa
Chiwoza
Chizinga
Chizu
Chizumba
Chongo
Choto
Chowe
Chulu
Daeang Luke  Hospital
Dambe
Dambo
Danda
Dedza
Dedza Boma
Dedza District
Dembo
Diamphwi
Dothi
Dowa
Dowa Boma
Dowa District
Dubai
Dwangwa
Dzabwa
Dzalanyama
Dzaleka
Dzedza
Dzenza
Dzoole
Dzuluwanda
Dzundi
Dzuwa
Ekwendeni
Embangweni
Emfenie
Falls
Fanwell
Federation
Fukamapiri
Fumbe
Gaga
Ganya
Gateway
Gawamadzi
Gologota
Gomani
Gonondo
Goodson Ganya
Guliver
Gulliver
Gulule
Gumbi
Gumbo
Gumulira
Guzani
Gwande
Gwengwe
Hanoki
Jalasi
Jaravikuba Munthali
Jaravikuwa
Jenda
Jodi
Johannesburg
Jolamu
Jumpha
Kabango
Kabudula
Kabuma
Kabunduli
Kabuthu
Kabvulunganya
Kabyela
Kabzera
Kabzyoko
Kachala
Kachele
Kachembere
Kachere
Kachigwada
Kachikho
Kachilele
Kachindamoto
Kachinga
Kachiwanda
Kachule
Kachulu
Kadete
Kadewere
Kadongola
Kaduwa
Kadzikhande
Kafulatila
Kafundu
Kalambo
Kalembo
Kalenga
Kalimbira
Kalimwini
Kaliyeka
Kaliyeka 1
Kaliyeka 2
Kalolo
Kalombo
Kalonga
Kalulu
Kaluluma
Kalumba
Kalumbu
Kalumo
Kaluzi
Kamadzi
Kamangirira
Kambala
Kambalame
Kambanizithe
Kambewa
Kambwiri
Kameme
Kamenyagwaza
Kamkundi
Kamnong'ona
Kamoyo
Kamphala
Kamphata
Kamphiri
Kamphoni
Kampingo Sibande
Kampini
Kamtotole
Kamundi
Kamuzu Barracks
Kamuzu College Of Nursing
Kamwana
Kamwendo
Kandaya
Kandikole
Kandiyani
Kanduku
Kanengo
Kanfosi
Kango
Kang'oma
Kang'ombe
Kaning'a
Kaningina
Kaning'ina Ward
Kanjedza
Kankhomba
Kankhulungu
Kanong'ona
Kantotole
Kanyamula
Kanyandula
Kanyenje
Kanyerere
Kanyoni
Kaondo
Kapalanga
Kapalasa
Kapanga
Kapedzera
Kapelula
Kapeni
Kapesi
Kaphata
Kaphiri
Kaphuka
Kapichi
Kapichira
Kapili
Kapoloma
Kapukwa
Karonga
Karonga District
Karonga Town
Kasakula
Kasisi
Kasiya
Kasonda
Kasumbu
Kasungu
Kasungu Boma
Kasungu District
Kasungu National Park
Katantha
Katawa
Katawa Ward
Katchale
Katchuka
Katete
Kathumba
Katola
Katondo
Katoto
Katoto Ward
Katsekaminga
Katukumala
Katuli
Katunga
Kauma
Kaundama
Kavala
Kavina
Kawala
Kawale
Kawale 1
Kawale 2
Kawamba
Kaweche
Kawerama
Kawere
Kawinga
Kawiza
Kawondo
Kawuma
Kayabwa
Kayembe
Khanda
Khola
Khomani
Khombe
Khombedza
Khongo
Khongoni
Khosolojere
Khwangwi
Khwidzi
Kilipula
Kiliyeka
Kuchata
Kudzula
Kulanga
Kuliyani
Kuluunda
Kumala
Kumalindi
Kumani
Kumbweza
Kumthulu
Kumtumanji
Kuntaja
Kunthembwe
Kunthulu
Kunthumbo
Kuntumanji
Kuthulu
Kwabingu
Kwachakwanira
Kwataine
Kwethemule
Kyungu
Lake Chilwa
Lake Chiuta
Lake Malawi
Lake Malawi Natl. Park - Mangochi
Lake Malawi Natl. Park - Salima
Lake Malombe
Lengwe National Park
Likangala
Likangala Central Ward
Likangala South Ward
Likangala Ward
Likhubula
Likhubula Ward
Likoma
Likoma District
Likoswe
Likuni
Lilongwe
Lilongwe City
Lilongwe Rural
Limbe
Limbe Central Ward
Limbe East Ward
Limbe West Ward
Lingadzi
Linthipe
Lisoka
Liwela
Liwilo
Liwonde
Liwonde National Park
Liwonde Town
Lizulu
Llkuni
Lodzanyama
Lombwa
Luchenza
Luchenza Town
Lukwa
Lumbadzi
Lundu
Mabuka
Mabulabo
Mabwera
Machilika
Machinga
Machinga Boma
Machinga District
Machinjiri
Madisi
Madzi
Madziakankhana
Maenje
Mafco
Mafosha
Magalamula
Maganga
Magomero
Magwero
Majete
Majete Game Reserve - Chikwawa
Majete Game Reserve - Mwanza
Majiga
Majomeka
Makalani
Makanga
Makanjira
Makanya
Makata
Makatani
Makhuwira
Makoka
Makwangwala
Makwenda
Makwinja
Malama
Malamulo
Malangalanga
Malembe
Malembo
Malemia
Malenga
Malengachanzi
Malengamzoma
Maligunde
Malikha
Malili
Malimbwe
Malingude
Malingunde
Maluwa
Mamina
Mangochi
Mangochi District
Mangochi Town
Mankhambira
Mantchichi
Maonde
Mapanga
Mapanga Ward
Mapila
Masambabise
Masasa
Masasa Ward
Masongola
Masongola Ward
Masula
Masumbankhunda
Mataka
Matapa
Matapila
Maula
Maula Prison
Maunda
Mavwere
Mawelo
Mayani
Mayenje
Mazengela
Mazengera
Maziro
Mbabvi
Mbalame
Mbang'gombe
M'bang'ombe
Mbavi
Mbelwaiv
Mbewa
Mbidzi
Mbingwa
Mbulu
Mbuna
Mbwadzulu
Mbwana Nyambi
Mbwananyambi
Mbwatalika
Mbwatwalika
Mbwemba
Mbwindi
Mchenga
Mchengautuwa
Mchengautuwa Ward
Mchenzi /Chatsika
Mchesi
Mchinji
Mchinji Boma
Mchinji District
Mchitanjiru
Mdabwi
Mdondwe
Mduwa
Mdzeka
Mgombe
Mgona
Mgubo
Mguwata
Michembo
Michiru
Michiru Ward
Mikondo
Mikundi
Misesa
Misesa Ward
Mitengo
Mitundu
Mjonja
Mkachuka
Mkakambo
Mkambwiri
Mkanda
Mkangamila
Mkangamira
Mkantho
Mkhota
Mkhumba
Mkhumbwe
Mkhwidzi
Mkomera
Mkozomba
Mkukula
Mkuwa
Mkuwazi
Mkwachuka
Mkwezalamba
Mkwichi
Mkwidzi
Mkwinda
Mlale
Mlambuzi
Mlanda
Mlangeni
Mlauli
Mlewa
Mlezi
Mlinga
Mlolo
Mlomba
Mlonyeni
Mlumbe
Mlumbwira
Mng'ongo
Mngwangwa
Mnjolo
Mnkhukwa
Mnthangombe
Monkey Bay
Monkey Bay Urban
Mozambique
Mpama
Mpando
Mpaweni
Mphambanya
Mphanyama
Mphanza
Mpherembe
Mphinzi
Mphonde
Mphunzi
Mphwetekere
Mpingu
Mponda
Mponela
Mponela Urban
Mponera
Mpumbulu
Msabwethunzi
Msakambewa
Msamala
Msamba
Msamba Ward
Msambo
Msampha
Msanama
Msanje
Msapha
Mseche
Msenga
Msewa
Msinja
Msinkhupuza
Msosa
Msukuma
Msundwe
Msungwi
Mtaja
Mtakataka
Mtali
Mtalimanja
Mtande
Mtandire
Mtanga
Mtchitanjiru
Mtchoka
Mtema
Mtemambalame
Mtengo
Mtengoowanthenga
Mtengowagwa
Mtenje
Mthang'ombe
Mthunga
Mthunthama
Mthyoka
Mtimuni
Mtsala
Mtsekwe
Mtsiliza
Mtsinje
Mtsiriza
Mtupanyama
Mtuwakale
Mtwalo
Mulanje
Mulanje Boma
Mulanje District
Mulanje Mountain Reserve
Muwalo
Muyenela
Muzu
Mvela
Mvimvi
Mvuwu
Mwabulambya
Mwachilala
Mwadenje
Mwadzama
Mwahenga
Mwakaboko
Mwakhundi
Mwambakanthu
Mwambo
Mwamlowe
Mwanamanga
Mwandenje
Mwanjema
Mwankhudi
Mwansambo
Mwanza
Mwanza Boma
Mwanza District
Mwase
Mwatibu
Mwaulambya
Mwaza
Mwenda
Mwenela
Mwenemisuku
Mwenewenya
Mwenyekondo
Mzazi
Mzedi
Mzedi Ward
Mzikubola
Mzimba
Mzimba Boma
Mzimba District
Mzingwa
Mziza
Mzukuzuku
Mzumara
Mzumazi
Mzuzu
Mzuzu City
Nachiola
Nakuwawa
Nalikule
Namalango
Namanga
Nambuma
Namitete
Namitondo
Namiyango
Namiyango Ward
Namulera
Namunje
Nancholi
Nancholi Ward
Nanganga
Nanjili
Nankumba
Nathenje
Nayele
Nazombe
Nchema
Nchesi
Nchilamwela
Ndamera
Ndaula
Nderemani
Ndevu
Ndilande
Ndindi
Ndirande
Ndirande North Ward
Ndirande South Ward
Ndirande West Ward
Nduwa
New Airport Site
Ng´Oma
Ngabu
Ngabu Urban
Ngomani
Ngomano
Ngongonda
Ngoni
Nguluwe
Ngwangwa
Ngwenya
Njewa
Njobvu
Njoka
Njolo
Njolomole
Njombwa
Njonja
Njovu
Njuchi
Nkalo
Nkanda
Nkaya
Nkhanda
Nkhangwi
Nkhata
Nkhata Bay
Nkhata Bay Boma
Nkhata Bay District
Nkhawale
Nkhokwa
Nkhoma
Nkhomphola
Nkhosa
Nkhotakota
Nkhotakota Boma
Nkhotakota District
Nkhotakota Game Reserve
Nkhukwa
Nkhundi
Nkhunga
Nkhungulu
Nkhwangwa
Nkhwangwi
Nkhwidzi
Nkolokoti
Nkolokoti Ward
Nkukula
Nkuwazi
Nsabwe
Nsalu
Nsamala
Nsambo
Nsampha
Nsana
Nsanama
Nsanda
Nsanje
Nsanje Boma
Nsanje District
Nsanjiko
Nsapha
Nsaru
Nsaru T.C
Nseru
Nsewa
Nsokoneza
Nsukuma
Nsundwe
Ntali
Ntandire
Ntchauya
Ntchentche
Ntcheu
Ntcheu Boma
Ntcheu District
Ntchisi
Ntchisi Boma
Ntchisi District
Ntema
Nthache
Nthalire
Nthang'ombe
Nthiramanja
Nthobwa
Nthondo
Nthondolo
Nthulu
Nthumba
Nthyoka
Nyama
Nyambadwe
Nyambadwe Ward
Nyambi
Nyambo
Nyangu
Nyanja
Nyemba
Nyika National Park - Chitipa
Nyika National Park - Karonga
Nyika National Park - Rumphi
Nzindo
Nzumara
Padzuwa
Pasimalo
Payele
Pemba
Penga
Phalombe
Phalombe Boma
Phalombe District
Phambala
Phatha
Phereni
Phirilanjuzi
Phula
Phwetekere
Piasani
Poko
Police Mobile Force
Pondamale
Rumphi
Rumphi Boma
Rumphi District
Saint Gabriel
Saint Johns
Salima
Salima District
Salima Town
Salu
Sambidwe
Samu
Sanje
Sanjiko
Sankhani
Saopa
Sapesa
Selengo
Senti
Seza
Shire
Simlemba
Simphasi
Simulemba
Sinda
Sinumbe
Sinyala
Sitola
Six Miles
Soche
Soche East Ward
Soche West Ward
Sokoloko
Somba
Sonkhwe
SOS
Sosola
South Lunzu
South Lunzu Ward
St Jones
State House
Suncity
Sungwi
TA Boghoyo
TA Bvumbwe
TA Chadza
TA Chakhumbira
TA Changata
TA Chapananga
TA Chigaru
TA Chikho
TA Chikowi
TA Chikulamayembe
TA Chikumbu
TA Chimaliro
TA Chimombo
TA Chimutu
TA Chimutu
TA Chimwala
TA Chindi
TA Chiseka
TA Chitera
TA Chitukula
TA Chiwere
TA Chulu
TA Dambe
TA Dzoole
TA Fukamapiri
TA Jalasi
TA Kabudula
TA Kabunduli
TA Kachindamoto
TA Kadewere
TA Kalembo
TA Kalolo
TA Kaluluma
TA Kalumba
TA Kalumbu
TA Kalumo
TA Kameme
TA Kanduku
TA Kanyenda
TA Kaomba
TA Kapelula
TA Kapeni
TA Kaphuka
TA Kapichi
TA Karonga
TA Kasakula
TA Kasisi
TA Kasumbu
TA Katuli
TA Katumbi
TA Katunga
TA Kawinga
TA Khombedza
TA Khongoni
TA Kilupula
TA Kuluunda
TA Kuntaja
TA Kunthembwe
TA Kuntumanji
TA Kwataine
TA Kyungu
TA Likoswe
TA Liwonde
TA Lundu
TA Mabuka
TA Mabulabo
TA Machinjili
TA Maganga
TA Makanjila
TA Makata
TA Makhwira
TA Malemia
TA Malenga Chanzi
TA Malenga Mzoma
TA Malili
TA Mankhambira
TA Masasa
TA Maseya
TA Mazengera
TA Mkanda
TA Mkhumba
TA Mkumpha
TA Mlauli
TA Mlolo
TA Mlonyeni
TA Mlumbe
TA M'Mbelwa
TA Mpama
TA Mpando
TA Mpherembe
TA Mponda
TA Msakambewa
TA Mtwalo
TA Mwabulambya
TA Mwadzama
TA Mwambo
TA Mwamlowe
TA Mwase
TA Mwenemisuku
TA Mwenewenya
TA Mzikubola
TA Mzukuzuku
TA Nankumba
TA Nazombe
TA Nchema
TA Nchilamwela
TA Ndamera
TA Ndindi
TA Ngabu
TA Njolomole
TA Nkalo
TA Nkanda
TA Nsabwe
TA Nsamala
TA Nthache
TA Nthalire
TA Nthiramanja
TA Nyambi
TA Pemba
TA Phambala
TA Santhe
TA Somba
TA Symon
TA Tambala
TA Tengani
TA Thomas
TA Timbiri
TA Usisya
TA Wasambo
TA Wimbe
TA Zolokere
TA Zulu
Taiza
Tambalale
Tambarale
Tanga
Tchetche
Technical College
Tengani
Thaulo
Thumba
Thyolo
Thyolo Boma
Thyolo District
Tidi
Timbiri
Timoti
Tonde
Tongole
Tsabango
Tsoyo
Tumbwe
Ukwe
Undi
Upper Falls
Viphya
Viphya Ward
Vwaza Marsh Reserve - Mzimba
Vwaza Marsh Reserve - Rumphi
Waliranji
Wasambo
Waya
White Falls
Wimbe
Zakazaka
Zakazaka Ward
Zapita
Zintambira
Zokoto
Zolozolo
Zolozolo Ward
Zomba
Zomba Central Ward
Zomba Municipality
Zomba Rural
Zulu
EOF
    return locations.split("\n")
  end

   def self.initialize_disticts
    districts = <<EOF
Balaka
Blantyre
Chikwawa
Chiradzulu
Chitipa
Dedza
Dowa
Karonga
Kasungu
Likoma
Lilongwe
Machinga
Mangochi
Mchinji
Mulanje
Mwanza
Mzimba
Neno
Nkhata Bay
Nkhotakota
Nsanje
Ntcheu
Ntchisi
Phalombe
Rumphi
Salima
Thyolo
Rumphi
EOF
    return districts.split("\n")
  end

   def self.initialize_tas
    tas = <<EOF
Boghoyo
Bvumbwe
Chadza
Chakhumbira
Changata
Chapananga
Chigaru
Chikho
Chikowi
Chikulamayembe
Chikumbu
Chimaliro
Chimombo
Chimutu
Chimutu
Chimwala
Chindi
Chiseka
Chitera
Chitukula
Chiwere
Chulu
Dambe
Dzoole
Fukamapiri
Jalasi
Kabudula
Kabunduli
Kachindamoto
Kadewere
Kalembo
Kalolo
Kaluluma
Kalumba
Kalumbu
Kalumo
Kameme
Kanduku
Kanyenda
Kaomba
Kapelula
Kapeni
Kaphuka
Kapichi
Karonga
Kasakula
Kasisi
Kasumbu
Katuli
Katumbi
Katunga
Kawinga
Khombedza
Khongoni
Kilupula
Kuluunda
Kuntaja
Kunthembwe
Kuntumanji
Kwataine
Kyungu
Likoswe
Liwonde
Lundu
Mabuka
Mabulabo
Machinjili
Maganga
Makanjila
Makata
Makhwira
Malemia
Malenga
Malenga
Malili
Mankhambira
Masasa
Maseya
Mazengera
Mkanda
Mkhumba
Mkumpha
Mlauli
Mlolo
Mlonyeni
Mlumbe
M'Mbelwa
Mpama
Mpando
Mpherembe
Mponda
Msakambewa
Mtwalo
Mwabulambya
Mwadzama
Mwambo
Mwamlowe
Mwase
Mwenemisuku
Mwenewenya
Mzikubola
Mzukuzuku
Nankumba
Nazombe
Nchema
Nchilamwela
Ndamera
Ndindi
Ngabu
Njolomole
Nkalo
Nkanda
Nsabwe
Nsamala
Nthache
Nthalire
Nthiramanja
Nyambi
Pemba
Phambala
Santhe
Somba
Symon
Tambala
Tengani
Thomas
Timbiri
Usisya
Wasambo
Wimbe
Zolokere
Zulu
EOF
    return tas.split("\n")
  end

  def self.initialize_health_facilities
    health_facilities = <<EOF
Bvumbwe Research Health Centre
Milonde Health Centre
Mkomaula Health Centre
Mtende Health Centre
Matope Rural Hospital
Nthalire Health Centre
Khola Health Centre
Kangolwa Health Centre
Chifunga Health Centre
Lulwe Health Centre
Mwatakale Health Post
Bondo Health Centre
Luwani Health Centre
Kaongozi Dispensary
Garrison Dispensary
Liwaladzi Health Centre
Kambenje Health Centre
Alinafe Rehabilitation Centre
Bwanje Health Centre
Kakoma Health Centre
Chiunda Dispensary
Lungwena Health Centre
Malombe Dispensary
Zingwangwa Health Centre
Mchacha Health Centre
Chapwaila Health Centre
Mdunga Health Centre
Salima District Hospital
Area 25 Health Centre
Nkhulambe Health Centre
Chilumba Rural Hospital
Senzani Health Centre
Ndamera Health Centre
Khuwi Health Centre
Iponga Health Centre
Makapwa Health Centre
Ntholowa
Tulokhondo Health Centre
Nathenje
Kasina Health Centre
Kamteteka Health Centre
Machinga Health Centre
Kaphatenga Health Centre
Nsabwe Dispensary
Lunjika Health Centre
Chikowa Health Centre
Kanyezi Health Centre
Zomba Prison Dispensary
Gombe Maternity
Ulongwe Health Centre
Chilonga Dispensary
Chilambwe Health Centre
Ngabu
Machereza Health Post
Chikuse
Kanyama Health Centre
Ntonda Rural Hospital
Msenjere Health Centre
Sister Martha Health Centre
Makwapala Health Centre
Mbalanguzi Dispensary
Kafere
Parachute Battallion Dispensary
Mtenthera
Matandani Health Centre
Mwangala Maternity
Mbalama Dispensary
Beleu
Bvumbwe Makungwa
Namanolo Health Centre
Mpepa
Misamvu Health Centre
Lemwe
Mbangombe Health Centre
Wimbe Health Centre
Chiradzulu District Hospital
Lilongwe Central Hospital
St Gabriel
Machinga District Hospital
St Joseph Hospital
Thyolo District Hospital
Lumbira
Nkhata Bay District Hospital
Bwaila/Bottom Hospital
State House Dispensary
Mtendere Health Centre
Euthini Rural Hospital
Mpemba Health Centre
Thambani Health Centre
St Vincent Health Centre
Kaundu
Katema Health Centre
Ntchisi District Hospital
Cobbe Barracks
Zomba Mental Hospital
Mwanza District Hospital
Mlambe Hospital
Mangochi District Hospital
Mulanje District Hospital
Karonga District Hospital
Balaka District Hospital
Neno Rural Hospital
Nkhotakota District Hospital
Daeyang Luke Hospital
Zomba Central Hospital
Likoma/St Peters
Chikwawa District Hospital
Madisi Hospital
Mchinji District Hospital
St. Annes Hospital
Mulanje Mission
Ntcheu District Hospital
Dedza District Hospital
Mbabzi Dispensary
Chithumba Maternity
Mvera Mission
Msakambewa Health Centre
Chimembe Health Centre
Malowa Dispensary
Chiendausiku
Chitekesa Health Centre
Kawale
Chilipa Health Centre
Jalasi Health Centre
Ngoni
Koche Health Centre
Guillime
Doviko Dispensary
Dzonzi Mvai Dispensary
Mlowe Health Centre
Mzokoto Health Centre
Lwezga Health Centre
Thuchila
Mkhota Health Centre
Gogode Dispensary
Ndunde Health Centre
Namikango
Kawamba Health Centre
Chiringa Maternity
Thondwe Health Centre
Katsekera Health Centre
Mkango Health Centre
Lulanga Health Centre
Mpiri Health Centre
Nsanama Health Centre
Naphimba Health Centre
Chisitu Health Centre
Chitedze Health Centre
Khosolo Health Centre
Naisi Health Centre
Kang'oma
Tcharo
Mwansambo Health Centre
Nasawa/Chimwalira Health Centre
Mtunthama Health Centre
Sorgin Health Centre
Mtimabi Health Centre
Jenda Health Centre
Mulibwanji Hospital
Namwera Health Centre
Queen Elizabeth Centre Hospital
Holy Family
Bulala Health Centre
Ndakwela Health Centre
Pirimiti Health Centre
Mikolongwe Health Centre
Malabada Health Centre
Mkhwayi Health Centre
Chimbalanga Health Centre
Nkhande Dispensary
Chingale Health Centre
Lupembe Health Centre
Ngana Health Centre
Newa Health Centre
Chintheche Rural Hospital
Mwazisi Health Centre
Namalaka Health Centre
Mlare Health Centre
Kasitu Health Centre
Lojwa Dispensary
Mpondasi Health Centre
Diampwe Health Centre
Ming'ongo
Thumbwe Health Centre
Likangala Health Centre
Mzalangwe Health Centre
Lunjeri Health Centre
Ngabu Rural Hospital
Chamba Dispensary
Masenjere Health Centre
Hara Dispensary
Kapiri Health Centre
Malembo
Mkanda Health Centre
Kachere Health Centre
Lambulira Health Centre
Nancholi Dispensary
Mpamantha Dispensary
Lumbadzi
Offesi Dispensary
Maperera Health Centre
Luwazi Health Centre
Thomasi Health Centre
Monkey Bay Health Centre
Mafco Health Centre
Chitipa District Hospital
Chididi Health Centre
Phanga Dispensary
Sankhulani Health Centre
Makata Dispensary
Chioshya Health Centre
Chileka Health Centre
Linyangwa Health Centre
Mbera Health Centre
Ngala Health Post
Namikoko Dispensary
Chadza/Unit 33
Wenya Health Centre
Ngokwe Health Centre
Mganja Maternity
Changata Health Centre
Dowa District Hospital
Mtakataka Health Centre
Mayani Health Centre
Nambiti 1
Nyambi Health Centre
Halena Oakely/Mtambanyama Clinic
Kapenda Health Centre
Mchoka Health Centre
Bowe Health Centre
Luwuchi Health Centre
Gawanani Health Centre
Dzoole Health Centre
Emfeni Health Centre
Mphunzi Health Centre
Nsiyaludzu Health Centre
Kasoba Health Centre
Area 18 Health Centre
Phalula Health Centre
Mkwepere Dispensary
Makhwira Health Centre
Matanda
Lengwe Dispensary
Chiponde Health Centre
Namisu Dispensary
Kalinde
Mhalaunda Health Centre
Chiwamba Health Centre
Chunjiza Health Centre
Mbonechela Dispensary
Mjini Dispensary
Milepa Health Centre
Kasinthula Dispensary
Mbalachanda Health Centre
Mulomba Health Centre
Masasa Dispensary
Mpherere Health Centre
Chonde Health Centre
Mponela Rural Hospital
Chulu Health Centre
Mbenje Health Centre
Chiwe Health Centre
Chang'ambika Health Centre
Luwawa Health Centre
Dzenza Health Centre
Chitala Health Centre
Matawale Health Centre
Mpamba Health Centre
H Parker Sharp Dispensary
Chididi Health Centre
Mpata Health Centre
Kapanga Health Centre
Bua Dispensary
Nsanje District Hospital
Bula Health Centre
Chilobwe/Majiga
Dickson Health Centre
Chitera Health Centre
Mauwa Health Centre
Santhe Health Centre
Jalawe Health Centre
Waruma
Chinthebe Dispensary
Manyamula Health Centre
South Lunzu Health Centre
Kasinje Health Centre
Limbe Health Centre
Mvera Army Clinic
Dwangwa Dispensary
Nayinunje Health Centre
Thonje Health Centre
Kwitanda Health Centre
Dzindevu
Gowa Health Centre
Chizolowondo Health Centre
Mkumba Health Centre
KTFT/Mziza Health Centre
Madziabango Health Centre
Ndirande Health Centre
Tsoyo
Kande Health Centre
Kamboni Health Centre
Namizana
Kanyimbi Health Centre
Ng'onga Health Centre
Bangwe Health Centre
Nyungwe Health Centre
Nankhwali Health Centre
Dzenje
Namasalima Health Centre
Machinjiri Health Centre
Nkhataombere
Mlanda Rural Hospital
Khombedza Health Centre
Mndinda
Police Hospital
Misomali Health Centre
Kapelula Health Centre
Ehehleni Dispensary
Khongoni
Makiyoni Health Centre
Utale I
Chagunda Dispensary
Kaseye Rural Hospital
Tengani Health Centre
Mkoma Health Centre
Nkhwazi Health Centre
Mphompha Health Centre
Chinkhwiri Health Centre
Chilipa Health Centre
Manjawira Maternity
Bua Dispensary
Chiumbangame Health Centre
Lundu Health Centre
Malembo Health Centre
Mlomba Dispensary
Chinguluwe Health Centre
Iba Dispensary
Dzaleka Refugee Camp Clinic
Lirangwe Health Centre
Mphati
Magamba Dispensary
St Martin Hospital
Kapeni Health Centre
Chingazi
Kayembe Health Centre
Namitambo Health Centre
Chisepo Health Centre
Kaname/Mdeza Dispensary
Chamba Dispensary
Edingeni Rural Hospital
Soche SDA Dispensary
Chiole Dispensary
Malamulo
Ndaula
Kalikumbi Health Centre
Ngwelelo Health Centre
Chileka Health Centre
Mbwatalika Health Centre
Matapila
Nsambe Health Centre
Mbang'ombe 11 Health Centre
Malingunde
Katete Rural Hospital
Biriwiri Health Centre
Nalunga Health Centre
Mbiza Health Centre
Chikweo Health Centre
Amalika Dispensary
Thekerani Health Centre
Dziwe Health Centre
Lifeline Health Centre
Msese Health Centre
Mzimba District Hospital
Mabiri Health Centre
Chimoto
Maonde Health Centre
Chitowo
Katchale
Lugola Health Centre
Thavite Health Centre
Misuku Health Centre
Mzenga Health Centre
Namanja Health Centre
Dolo Health Centre
Ruarwe Dispensary
Chimvu
Golomoti Health Centre
Mikondo Health Centre
Mlangeni Health Centre
Chikande Health Centre
Chilomoni Health Centre
Migowi Health Centre
Namasalima Health Centre
Dwambadzi Rural Hospital
Molere Health Centre
St Montfort Hospital
Chikangawa Health Centre
Kaigwazanga Health Centre
Mhuju Rural Hospital
Mphepozinai Dispensary
Balaka Health Centre
Kamsonga Health Centre
Champiti Health Centre
Kaloga Maternity
Zomba City Clinic
Kawinga Health Centre
Mbingwa Health Centre
Utale II Health Centre
Senga Bay Baptist Health Centre
Madede Health Centre
Endindeni Health Centre
Chankhungu
Chinthembwe Health Centre
Tembwe Dispensary
Namadzi Health Centre
Khondowe
Chitimba Health Centre
Kabudula Rural Hospital
Bimbi Health Centre
Chigodi Health Centre
Lobi Health Centre
Mikundi Health Centre
Kunenekude Health Centre
Chipumi Health Centre
Old Maula Health Centre
DGM
Nkope Health Centre
Rumphi District Hospital
Vibangalala Dispensary
Hoho Health Centre
Chisala Health Centre
Kasese/Lifeline Malawi Health Centre
Chitsimuka Health Centre
Mposa Health Centre
Gola
Kaluluma Rural Hospital
Mluma
Magaleta Health Centre
Mpala Health Centre
Nthungwa Health Centre
Nangalamu Health Centre
Muloza Heath Centre
Nkhoma
Mfera Health Centre
Phokera Health Centre
Magomero Health Centre
Chesamu Health Centre
Chabvala Health Centre
Nkasala Health Centre
Liuzi Health Centre
Chiringa Cham Health Centre
Nambazo Health Centre
Likuni Hospital
Ntaja Health Centre
Benga Health Centre
Wiliro Health Centre
Mapanga Clinic
Kameme Health Centre
Mdeka Health Centre
Nankumba Health Centre
Makhanga Health Centre
Chimaliro Health Centre
Chinyama Health Centre
Kadango Dispensary
Kukalanga Dispensary
Mase Health Centre
Katowo Rural Hospital
Chakhaza Health Centre
Chingoni
Mitundu
Makanjira Health Centre
Lizulu Health Centre
Ifumbo Health Centre
Kampanje
Mayaka Health Centre
Ludzi Rural Hospital
Mitengo Health Centre
Neno Parish Health Centre
Sukasanje Health Centre
Mtengowanthenga Hospital
Kapiri Mission Hospital
Mwanga Health Centre
Nakalanzi
Nkhamenya Hospital
St. Joseph
Kankao Health Centre
Namulenga Health Centre
St Patricks Rural Hospital
St Mary's
Luwerezi Health Centre
Lake View Health Centre
Mbulumbuzi Health Centre
Sister Theresa Rural Hospital
Kalemba Health Centre
Matiya Health Centre
Sharpe Valley Health Centre
Mzama Health Centre
Mlale
Atupele Community Hospital
Ngodzi Health Centre
Nsipe Rural Hospital
Mzambazi Rural Hospital
Nambuma Health Centre
Bembeke
St. Annes Health Centre
Tsangano Health Centre
Chipini Rural Hospital
Mpasa Health Centre
Chitheka Health Centre
Simulemba Health Centre
Katuli Health Centre
Chambe Health Centre
Chipho Health Centre
Nkalo Health Centre
Mlolo Health Centre
Fulirwa Health Centre
Kasalika Health Centre
Ganya Maternity
Khonjeni Health Centre
Kalembo Dispensary
Malomo Health Centre
Kalulu Health Centre
Zoa Health Centre
Kaphuka Rural Hospital
Gaga Health Centre
Phalombe
Domasi Rural Hospital
Chimwankango
Nayuchi Health Centre
Bilira Health Centre
Chileka SDA
Kamphata Health Centre
Kazyozyo/Sakhuta Maternity
Trinity Hospital
Katimbira Health Centre
Mkhuzi
Maganga Health Centre
Usisya Health Centre
Chamwabvi Dispensary
Gumba Health Post
Lura Health Centre
Ukwe
Nyamithuthu Health Centre
Nsaru
Bolero Rural Hospital
Mkumaniza Health Centre
Mtosa Health Centre
Phirilongwe Health Centre
Nkhunga Health Centre
Mulangali
Mimosa
Chikwina Health Centre
Chipoka Health Centre
Nthenje Health Centre
Chinguluwe Health Centre
PIM Health Centre
Chambo Health Centre
St Mary's/Chizumulu Health Centre
Phimbi Health Centre
Mzuzu Central Hospital
Balaka BLM
Comfort
Lunzu BLM
Midima BLM
Ndirande BLM
Railways CEAR Clinic
Zingwangwa BLM
Kapichira Clinic
Ngabu BLM
Sucoma/Illovo Clinic
Dedza BLM
Dowa BLM
Family Planning Association of Malawi
Karonga BLM
Maneno Private Clinic
Wovwe Escom Clinic
Banja La Mtsogolo
Gogo LEA PVT Clinic
ABC Community Clinic
Adventist health center Area 14
Area 25 BLM
Bunda Clinic
Chimwala
Chimwala Clinic
Dzalanyama/Kapombeza
Falls BLM
Kawale BLM
Malangalanga
Malawi Army Air Wing Clinic
Mlodza/Seventh Day
SOS Medical Centre
Liwonde BLM
Assalam Clinic
Mangochi BLM
Mchinji BLM
Mulanje BLM
Mwanza BLM
Nkula Clinic
Mzimba BLM
Mzuzu BLM
Kawalazi Estate Clinic
Nkhatabay BLM
Centre 3 Clinic
Dwangwa BLM
Dwangwa Cane Grower Ltd Clinic
Kasasa Clinic
Nkhotakota BLM
Nyamvuu Clinic
Ukasi Clinic
Ntcheu BLM
Eva Demaya Private Clinic
Rumphi BLM
Admarc
Salima BLM
Bvumbwe BLM
Adventist Health Services Clinic
Zomba BLM
Blantyre Civil Centre Health Centre
Chichiri Prison Dispensary
Limbe ADMARC Health Centre
Mitsidi Dispensary
80 Block Clinic
Chisinga Dispensary
Ofesi
City Assembly Health
New state house
Police/Area 30
Liwonde SDA Health Centre
Sinyala Dispensary
Malalwi Army Marine Dispensary
Maldeco Dispensary
Ekwaiweni Dispensary
Lusangazi Dispensary
Matuli Dispensary
Mzuzu Police Dispensary
Raiply Dispensary
Chombe Estate Dispensary
Kavuzi Dispensary
Vizara Dispensary
Kanyimbi
Mlangeni/Police Dispensary
Dzunje Dispensary
Kaombe Dispensary
Mndinda Dispensary
Salima Admarc Dispensary
Municipal Clinic
Forestry Dispensary
Ngabu SDA Health Centre
Chithumba
St Mary Rehabilitation
Sangilo Health Centre
Chamama Health Centre
Kapyanga Health Centre
Mpasazi Health Centre
Thupa Health Centre
Chinsapo
Khasu
Madalitso Health Centre
Mwalasi
Malukula Health Centre
Nyangu Health Centre
Sable Health Centre
Kazyozyo
Thembe
Choma Health Centre
Emsizini Health Centre
Kabuwa Health Centre
Kabwafu Health Centre
Kafukule Health Centre
Luvwere Health Centre
Malidade Health Centre
Moyale Health Centre
Mpherembe Health Centre
Mtwalo Health Centre
Njuyu Health Centre
Nkholongo Health Centre
Nkhuyukuyu Health Centre
Tchesamu Health Centre
Matiki Health Centre
Msenjere
Nambiti 2
Bwengu Health Centre
Engucwini Health Centre
Enukweni Health Centre
Kamwe Health Centre
Kasambala Health Centre - mispelled? - doesn't exist
Luzi Health Centre
Thunduwike Health Centre
Golomoti Health Centre
Lifuwu Health Centre
M'mambo Health Centre
Mkango
Blantyre Adventist
Ekwendeni Hospital
Mumbwe Medical Centre
St Johns Hospital
Phalombe Mission
Livingstonia Hospital
Mua Hospital
Soche Maternity
Mayani Maternity
Mphunzi Maternity
St John of God
Kasauka Nutr; Rehab; unit
Mzuzu Urban Health Centre
Macro Blantyre Clinic
Macro Lilongwe
Macro Mzuzu
Mtakataka/Police College Health Centre
St. Lukes Rural Hospital
Maluwa
Kandeu Dispensary
Ngala Health Centre
Nthondo
St Andrews Health Centre
Luwalika Health Centre
Mangunda Clinic
Chapananga Health Centre
Kasungu District Hospital
Embangweni Hospital
Namphungo Health Centre
Matumba Health Centre
Lisungwi Health Centre
Chikole Dispensary
Bilal Dispensary
Mzandu Health Centre
Nthondo Dispensary
Ligowe Health Centre
Kochilila
Ching'oma Health Centre
Kaporo Rural Hospital
Chikowa Health Centre
Namandanje Health Centre
Kapire Health Centre
Mbenje Temp (refugee?)
Tengani Temp (refugee?)
Mazamba
Phirisingo
Chelinda
Ku Chawe
Mikuyu
Malavi
Zomba DHO
Kasungu Prison
Lifupa
Blantyre DHO
College of Nursing
Kanjedza Police
Kamuzu Barracks
Lilongwe DHO
Mzuzu Dispensary
EOF
    return health_facilities.split("\n")
  end



  @@current_residences = initialize_current_residences()
  @@areas = initialize_areas()
  @@districts = initialize_disticts()
  @@tas = initialize_tas()
  @@health_facilities = initialize_health_facilities()

end
