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

  @@current_residences = initialize_current_residences()
  @@areas = initialize_areas()

end
