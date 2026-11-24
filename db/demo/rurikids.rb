# The landing's example tree (docs/features/landing.md): Rurik to Vladimir Monomakh, everyone long dead, so a
# guest on its view link sees all of it. Built by the development seeds and, on a live install, by
# `bin/rails demo:rurikids OWNER=email`. Portraits: db/seed_images (app/assets/images/NOTICE.md).
class Rurikids
  NAME = "Рюриковичи"
  IMAGES = Pathname(__dir__).join("../seed_images")

  PLACES = {
    "Новгород" => [ 58.5215, 31.2755 ], "Киев" => [ 50.4501, 30.5234 ], "Псков" => [ 57.8136, 28.3496 ],
    "Искоростень" => [ 50.9500, 28.6400 ], "Днепровские пороги" => [ 47.8400, 35.1000 ],
    "Берестово" => [ 50.4340, 30.5570 ], "Полоцк" => [ 55.4879, 28.7856 ], "Вышгород" => [ 50.5845, 30.4897 ],
    "Сигтуна" => [ 59.6175, 17.7236 ], "Нежатина Нива" => [ 51.4900, 31.2900 ], "Переяславль" => [ 50.0656, 31.4458 ]
  }.freeze

  def self.build!(owner:) = new(owner).build!

  def initialize(owner)
    @owner = owner
  end

  def build!
    rt = @owner.trees.find_by(name: NAME) ||
      Tree.create!(name: NAME).tap { it.tree_memberships.create!(user: @owner, role: "owner") }

    if rt.people.none?

      # Поколение I — Рюрик
      рюрик  = pers(rt, given_names: "Рюрик",   surname: nil, sex: "M")
      ефанда = pers(rt, given_names: "Ефанда", surname: nil, sex: "F")
      evt(рюрик, kind: "DEAT", date: "879",  value: "Новгород")
      evt(ефанда, kind: "DEAT")
      evt(рюрик, kind: "OCCU",               value: "Князь новгородский, родоначальник династии")
      evt(рюрик, kind: "EVEN", date: "862",  value: "Призвание варягов: сел княжить в Ладоге, затем в Новгороде")

      # Поколение II — Игорь и Ольга
      игорь = pers(rt, given_names: "Игорь Рюрикович", surname: nil, sex: "M", nickname: "Старый")
      ольга = pers(rt, given_names: "Ольга",           surname: nil, sex: "F", nickname: "Святая")
      evt(игорь, kind: "BIRT", date: "ок. 878")
      evt(игорь, kind: "DEAT", date: "945",       value: "Искоростень")
      evt(игорь, kind: "OCCU",                    value: "Великий князь киевский")
      evt(игорь, kind: "EVEN", date: "941",       value: "Поход на Константинополь; флот сожжён «греческим огнём»")
      evt(игорь, kind: "EVEN", date: "944",       value: "Второй поход на Византию и договор с греками")
      evt(ольга, kind: "BIRT", date: "ок. 920")
      evt(ольга, kind: "DEAT", date: "11 ИЮЛ 969", value: "Киев")
      evt(ольга, kind: "OCCU",                     value: "Правительница Руси при малолетнем сыне")
      evt(ольга, kind: "EVEN", date: "ок. 957",    value: "Крещение в Константинополе")
      fam(rt, partners: [ рюрик, ефанда ], children: [ игорь ])
      f2 = fam(rt, partners: [ игорь, ольга ])
      evt(f2, kind: "MARR", date: "903", value: "Псков")

      # Поколение III — Святослав
      свят  = pers(rt, given_names: "Святослав Игоревич", surname: nil, sex: "M", nickname: "Храбрый")
      малуша = pers(rt, given_names: "Малуша",            surname: nil, sex: "F")
      evt(свят, kind: "BIRT", date: "942",  value: "Киев")
      evt(свят, kind: "DEAT", date: "972",  value: "Днепровские пороги")
      evt(свят, kind: "OCCU",               value: "Великий князь киевский")
      evt(свят, kind: "EVEN", date: "965",  value: "Разгром Хазарского каганата")
      evt(свят, kind: "EVEN", date: "971",  value: "Осада в Доростоле и мир с императором Иоанном Цимисхием")
      evt(малуша, kind: "OCCU", value: "Ключница княгини Ольги")
      evt(малуша, kind: "DEAT")
      f2.children << свят
      f3 = fam(rt, partners: [ свят, малуша ])

      # Поколение IV — Владимир и Рогнеда
      влад    = pers(rt, given_names: "Владимир Святославич", surname: nil, sex: "M", nickname: "Красное Солнышко")
      рогнеда = pers(rt, given_names: "Рогнеда Рогволодовна", surname: nil, sex: "F", nickname: "Горислава")
      evt(влад, kind: "BIRT", date: "ок. 960")
      evt(влад, kind: "DEAT", date: "15 ИЮЛ 1015", value: "Берестово")
      evt(влад, kind: "BURI", date: "1015",        value: "Киев")
      evt(влад, kind: "OCCU",                      value: "Великий князь киевский")
      evt(влад, kind: "EVEN", date: "988",         value: "Крещение Руси")
      evt(рогнеда, kind: "BIRT", date: "ок. 962", value: "Полоцк")
      evt(рогнеда, kind: "DEAT", date: "ок. 1000")
      f3.children << влад
      f4 = fam(rt, partners: [ влад, рогнеда ])
      evt(f4, kind: "MARR", date: "ок. 978", value: "Полоцк")

      # Поколение V — Ярослав Мудрый и Ингигерда
      изяс_в = pers(rt, given_names: "Изяслав Владимирович", surname: nil, sex: "M")
      яросл  = pers(rt, given_names: "Ярослав Владимирович", surname: nil, sex: "M", nickname: "Мудрый")
      ингиг  = pers(rt, given_names: "Ингигерда",            surname: nil, sex: "F", nickname: "Ирина")
      evt(изяс_в, kind: "BIRT", date: "ок. 979")
      evt(изяс_в, kind: "DEAT", date: "1001",       value: "Полоцк")
      evt(изяс_в, kind: "OCCU",                     value: "Князь полоцкий")
      evt(яросл, kind: "BIRT", date: "ок. 978")
      evt(яросл, kind: "DEAT", date: "20 ФЕВ 1054", value: "Вышгород")
      evt(яросл, kind: "BURI", date: "1054",        value: "Киев")
      evt(яросл, kind: "OCCU",                      value: "Великий князь киевский")
      evt(ингиг, kind: "BIRT", date: "ок. 1001",    value: "Сигтуна")
      evt(ингиг, kind: "DEAT", date: "10 ФЕВ 1050", value: "Новгород")
      f4.children << [ изяс_в, яросл ]
      f5 = fam(rt, partners: [ яросл, ингиг ])
      evt(f5, kind: "MARR", date: "1019")

      # Поколение VI — дети Ярослава
      анаст  = pers(rt, given_names: "Анастасия Ярославна", surname: nil, sex: "F")
      елиз   = pers(rt, given_names: "Елизавета Ярославна", surname: nil, sex: "F")
      изяс_я = pers(rt, given_names: "Изяслав Ярославич",   surname: nil, sex: "M")
      свят_я = pers(rt, given_names: "Святослав Ярославич", surname: nil, sex: "M")
      всев   = pers(rt, given_names: "Всеволод Ярославич",  surname: nil, sex: "M")
      анна   = pers(rt, given_names: "Анна Ярославна",      surname: nil, sex: "F")
      evt(анаст,  kind: "BIRT", date: "ок. 1023")
      evt(анаст,  kind: "DEAT", date: "ок. 1074")
      evt(анаст,  kind: "OCCU",                      value: "Королева Венгрии")
      evt(елиз,   kind: "BIRT", date: "ок. 1025")
      evt(елиз,   kind: "DEAT", date: "после 1066")
      evt(елиз,   kind: "OCCU",                      value: "Королева Норвегии, затем Дании")
      evt(изяс_я, kind: "BIRT", date: "1024")
      evt(изяс_я, kind: "DEAT", date: "3 ОКТ 1078",  value: "Нежатина Нива")
      evt(изяс_я, kind: "OCCU",                      value: "Великий князь киевский")
      evt(свят_я, kind: "BIRT", date: "1027")
      evt(свят_я, kind: "DEAT", date: "27 ДЕК 1076", value: "Киев")
      evt(свят_я, kind: "OCCU",                      value: "Князь черниговский, великий князь киевский")
      evt(всев,   kind: "BIRT", date: "1030")
      evt(всев,   kind: "DEAT", date: "13 АПР 1093", value: "Вышгород")
      evt(всев,   kind: "OCCU",                      value: "Князь переяславский, великий князь киевский")
      evt(анна,   kind: "BIRT", date: "ок. 1032",    value: "Киев")
      evt(анна,   kind: "DEAT", date: "после 1075")
      evt(анна,   kind: "OCCU",                      value: "Королева Франции")
      evt(анна,   kind: "EVEN", date: "1051",        value: "Венчание с Генрихом I, королём Франции, в Реймсе")
      f5.children << [ анаст, елиз, изяс_я, свят_я, всев, анна ]

      # Поколение VII — Владимир Мономах
      мария = pers(rt, given_names: "Мария", surname: nil, sex: "F", nickname: "Мономахиня")
      моном = pers(rt, given_names: "Владимир Всеволодович", surname: nil, sex: "M", nickname: "Мономах")
      evt(мария, kind: "DEAT", date: "1067")
      evt(моном, kind: "BIRT", date: "1053")
      evt(моном, kind: "DEAT", date: "19 МАЙ 1125", value: "Переяславль")
      evt(моном, kind: "BURI", date: "1125",        value: "Киев")
      evt(моном, kind: "OCCU",                      value: "Великий князь киевский; автор «Поучения»")
      f6 = fam(rt, partners: [ всев, мария ], children: [ моном ])
      evt(f6, kind: "MARR", date: "ок. 1046")

    end

    # ── Ярослав Мудрый: хронология (идемпотентно) ────────────────────────────
    яросл = rt.people.find_by!(given_names: "Ярослав Владимирович")

    [
      [ "ок. 1010", "Отец посадил княжить в Новгороде" ],
      [ "1014",     "Отказался платить дань Киеву; отец собирает поход на сына" ],
      [ "1015",     "Смерть отца; начало усобицы со Святополком" ],
      [ "1016",     "Победа над Святополком под Любечем; впервые занял Киев. Новгородцам дана «Правда Ярослава»" ],
      [ "1018",     "Поражение на Буге от Болеслава Храброго; Киев снова потерян" ],
      [ "1019",     "Битва на Альте; окончательно утвердился в Киеве. Женитьба на Ингигерде Шведской" ],
      [ "1024",     "Битва у Листвена с братом Мстиславом; Русь поделена по Днепру" ],
      [ "1036",     "Разгром печенегов у стен Киева; на месте битвы заложен Софийский собор" ],
      [ "1037",     "Золотые ворота Киева; при Софии собраны переписчики и переводчики книг" ],
      [ "1051",     "Иларион поставлен митрополитом — первый русский на этой кафедре" ],
      [ "1054",     "Завещание сыновьям: «имейте любовь между собою»; кончина в Вышгороде" ]
    ].each do |(date, desc)|
      evt(яросл, kind: "EVEN", date: date, value: desc)
    end

    # ── Рюриковичи: биографии ─────────────────────────────────────────────────
    рюрик   = rt.people.find_by!(given_names: "Рюрик")
    ефанда  = rt.people.find_by!(given_names: "Ефанда")
    ольга   = rt.people.find_by!(given_names: "Ольга")
    свят    = rt.people.find_by!(given_names: "Святослав Игоревич")
    влад    = rt.people.find_by!(given_names: "Владимир Святославич")
    рогнеда = rt.people.find_by!(given_names: "Рогнеда Рогволодовна")
    анна    = rt.people.find_by!(given_names: "Анна Ярославна")
    мария   = rt.people.find_by!(given_names: "Мария")
    моном   = rt.people.find_by!(given_names: "Владимир Всеволодович")

    bio рюрик, <<~HTML
      <p>Рюрик (ум. 879) — варяжский князь, родоначальник династии, правившей Русью более семисот лет.
      По «Повести временных лет», в 862 году его вместе с братьями Синеусом и Трувором призвали
      княжить словене, кривичи и чудь: «земля наша велика и обильна, а порядка в ней нет».</p>
      <p>Сначала сел в Ладоге, затем в Новгороде. Умирая, передал княжение родственнику Олегу
      и поручил ему малолетнего сына Игоря.</p>
    HTML

    bio ефанда, <<~HTML
      <p>Ефанда — жена Рюрика и мать Игоря по Иоакимовской летописи, которую знают только в пересказе
      В.Н. Татищева. Ни «Повесть временных лет», ни другие ранние источники её не называют,
      поэтому многие историки считают её фигурой предания.</p>
      <p>Связь записана с низкой уверенностью — так древо честно показывает, что известно, а что
      только предполагается.</p>
    HTML

    bio ольга, <<~HTML
      <p>Княгиня Ольга (ок. 920 — 969) — жена Игоря, правила Русью при малолетнем Святославе.
      Жестоко отомстила древлянам за гибель мужа, а затем первой упорядочила сбор дани:
      установила «уставы и уроки», «погосты и становища».</p>
      <p>Около 957 года крестилась в Константинополе и стала первой христианкой среди правителей Руси.
      Святослав креститься отказался — боялся насмешек дружины. Причислена к лику святых
      как равноапостольная.</p>
    HTML

    bio свят, <<~HTML
      <p>Святослав Игоревич (942–972) — князь-воин. Летопись пишет, что он ходил в походы налегке:
      без обоза и котлов, спал на потнике, седло в головах. Врагам посылал предупреждение:
      «Хочу на вы идти».</p>
      <p>Разгромил Хазарский каганат, воевал на Дунае и хотел перенести столицу в Переяславец.
      Возвращаясь из похода на Византию, погиб у днепровских порогов в бою с печенегами.</p>
    HTML

    bio влад, <<~HTML
      <p>Владимир Святославич (ок. 960 — 1015) — сын Святослава и ключницы Малуши. В былинах —
      «Владимир Красное Солнышко». В 988 году крестил Русь, взяв в жёны византийскую царевну Анну.</p>
      <p>Строил крепости по рекам против печенегов, поставил в Киеве Десятинную церковь.
      Умер в Берестове, когда собирался в поход на сына Ярослава, отказавшегося платить дань.</p>
    HTML

    bio рогнеда, <<~HTML
      <p>Рогнеда Рогволодовна (ок. 962 — ок. 1000) — дочь полоцкого князя Рогволода. Отказала
      Владимиру — «не хочу разуть робичича», — и он взял Полоцк силой и сделал её женой.</p>
      <p>Мать Изяслава и Ярослава Мудрого. По преданию, получила имя Горислава за горькую судьбу,
      а в конце жизни постриглась в монахини под именем Анастасии.</p>
    HTML

    bio яросл, <<~HTML
      <p>Ярослав Владимирович Мудрый (ок. 978 — 1054) — великий князь киевский, праправнук Рюрика.
      После долгой войны с братьями объединил Русь и правил ею больше тридцати лет.</p>
      <p>При нём записали «Русскую правду» — первый свод законов, построили Софийские соборы в Киеве
      и Новгороде и Золотые ворота, а при Софии Киевской собрали переписчиков и первую большую
      библиотеку.</p>
      <p>Через детей породнился с половиной Европы: дочери стали королевами Венгрии, Норвегии
      и Франции, сыновья женились на польской, византийской и немецкой принцессах.</p>
      <h3>Что осталось после него</h3>
      <ul>
        <li>«Правда Ярослава» — древнейшая часть «Русской правды»</li>
        <li>Софийский собор в Киеве (заложен в 1037)</li>
        <li>Софийский собор в Новгороде (построен сыном Владимиром, 1045–1050)</li>
        <li>Золотые ворота Киева</li>
      </ul>
    HTML

    bio анна, <<~HTML
      <p>Анна Ярославна (ок. 1032 — после 1075) — дочь Ярослава Мудрого, королева Франции.
      В 1051 году в Реймсе обвенчалась с Генрихом I. Мать короля Филиппа I.</p>
      <p>Её подпись кириллицей — «Ана ръина», то есть «Анна королева», — сохранилась на грамоте
      1063 года: редкий автограф древнерусской княжны.</p>
    HTML

    bio мария, <<~HTML
      <p>Жена Всеволода Ярославича и мать Владимира Мономаха — по преданию, родственница
      византийского императора Константина IX Мономаха. Её имя в источниках не названо:
      «Мария» и «Анастасия» — лишь предположения историков.</p>
    HTML

    bio моном, <<~HTML
      <p>Владимир Всеволодович Мономах (1053–1125) — внук Ярослава Мудрого и, по матери, потомок
      византийских императоров. Созвал Любечский съезд князей (1097): «каждый да держит
      отчину свою».</p>
      <p>Оставил «Поучение» детям — первый на Руси рассказ правителя о своей жизни. С его именем
      предание связывает шапку Мономаха.</p>
    HTML

    # ── Рюриковичи: источники ─────────────────────────────────────────────────
    s1 = src(rt,
      title: "Повесть временных лет",
      citation_text: "Летописный свод начала XII века. Лаврентьевский список, 1377 г. — РНБ, F.п.IV.2. " \
                     "Основной источник о Рюрике, Игоре, Ольге, Святославе, Владимире и Ярославе.",
      url: "https://ru.wikisource.org/wiki/Повесть_временных_лет")

    s2 = src(rt,
      title: "Новгородская первая летопись",
      citation_text: "Синодальный и Комиссионный списки, XIII–XV вв. Сохранила черты свода, " \
                     "более раннего, чем «Повесть временных лет».")

    s3 = src(rt,
      title: "Татищев В.Н. История Российская",
      citation_text: "Первое издание — М., 1768–1784. Единственный источник Иоакимовской летописи, " \
                     "известной лишь в пересказе Татищева.")

    s4 = src(rt,
      title: "Царский титулярник, 1672",
      citation_text: "«Большая государственная книга» Посольского приказа. Портреты князей — " \
                     "условные, написаны через семьсот лет после их жизни.")

    s5 = src(rt,
      title: "Карамзин Н.М. История государства Российского",
      citation_text: "Т. 1–2. СПб., 1816–1818.",
      url: "https://ru.wikisource.org/wiki/История_государства_Российского_(Карамзин)")

    [ рюрик, ольга, свят, влад, рогнеда, яросл, анна, моном ].each { cite(s1, it) }
    cite(s2, рюрик); cite(s5, яросл); cite(s5, анна)
    [ рюрик, ольга, свят, влад, яросл, моном ].each { cite(s4, it) }
    cite(s3, ефанда).update!(confidence: "low")
    cite(s3, fam(rt, partners: [ рюрик, ефанда ])).update!(confidence: "low")

    # ── Рюриковичи: портреты ──────────────────────────────────────────────────
    photo рюрик,   "rurik.jpg"       # Царский титулярник, 1672
    photo ольга,   "olga.jpg"        # икона
    photo свят,    "svyatoslav.png"  # Царский титулярник, 1672
    photo влад,    "vladimir.jpg"    # Царский титулярник, 1672
    photo рогнеда, "rogneda.jpg"     # А.П. Лосенко, «Владимир и Рогнеда», 1770 (фрагмент)
    photo яросл,   "yaroslav.jpg"    # Царский титулярник, 1672
    photo моном,   "monomakh.jpg"    # Царский титулярник, 1672

    rt.share_link || rt.create_share_link!
    rt
  end

  private
    def pers(tree, given_names:, surname:, sex:, nickname: nil)
      tree.people.find_or_create_by!(given_names: given_names, surname: surname) do |person|
        person.sex = sex
        person.nickname = nickname
      end
    end

    def evt(subject, kind:, date: nil, value: nil)
      subject.events.find_or_create_by!(kind: kind, date_raw: date) do |event|
        if (latitude, longitude = PLACES[value])
          event.assign_attributes(place_name: value, place_latitude: latitude, place_longitude: longitude)
        else
          event.value = value
        end
      end
    end

    def fam(tree, partners: [], children: [])
      partner_ids = partners.map(&:id).sort
      tree.families.find { it.partners.pluck(:id).sort == partner_ids } ||
        tree.families.create!.tap { it.partners << partners; it.children << children }
    end

    def src(tree, title:, citation_text: nil, url: nil)
      tree.sources.find_or_create_by!(title: title) { it.citation_text = citation_text; it.url = url }
    end

    def cite(source, citable)
      Citation.find_or_create_by!(source: source, citable: citable)
    end

    def bio(person, html)
      person.update!(biography: html) if person.biography.blank?
    end

    def photo(person, filename)
      return if person.avatar.attached?
      path = IMAGES.join(filename)
      person.avatar.attach(io: path.open, filename: filename, content_type: Marcel::MimeType.for(path)) if path.exist?
    end
end
