class BookContext {
  final String en;
  final String am;
  const BookContext({required this.en, required this.am});
}

class StudyData {
  static const Map<String, BookContext> books = {
    'genesis': BookContext(en: 'Written by Moses ~1445 BC. Genesis means "beginnings" — creation, humanity\'s fall, the flood, and God\'s covenant with Abraham, Isaac, and Jacob.', am: 'በሙሴ የተጻፈ፣ ~1445 ዓ.ዓ. ዘፍጥረት ማለት "መጀመሪያ" ማለት ነው — ፍጥረትን፣ የሰው ውድቀትን፣ የጥፋት ውኃን፣ ከአብርሃም፣ ይስሐቅና ያዕቆብ ጋር ያለውን ቃል ኪዳን ይገልጻል።'),
    'exodus': BookContext(en: 'Written by Moses ~1445 BC. Israel\'s slavery in Egypt, the plagues, Passover, the Red Sea crossing, and the giving of the Law at Mount Sinai.', am: 'በሙሴ የተጻፈ፣ ~1445 ዓ.ዓ. የእስራኤል ባርነት በግብጽ፣ መቅሰፍቶች፣ ፋሲካ፣ የቀይ ባህር መሻገሪያ፣ በሲና ተራራ ሕግ መሰጠት።'),
    'leviticus': BookContext(en: 'Written by Moses ~1445 BC. A manual for holy living — laws about sacrifice, priesthood, purity, and how a holy God dwells among His people.', am: 'በሙሴ የተጻፈ፣ ~1445 ዓ.ዓ. ስለ ቅዱስ ኑሮ መመሪያ — ስለ መሥዋዕት፣ ክህነት፣ ንጽሕና፣ ቅዱስ አምላክ በሕዝቡ መካከል እንዴት እንደሚያድር ያሳያል።'),
    'numbers': BookContext(en: 'Written by Moses ~1405 BC. Israel\'s 40 years in the wilderness — testing, rebellion, and God\'s faithful provision despite unbelief.', am: 'በሙሴ የተጻፈ፣ ~1405 ዓ.ዓ. የእስራኤል 40 ዓመታት በምድረ በዳ — ፈተና፣ ዓመፅ፣ እና የእግዚአብሔር ታማኝ አቅርቦት በማያምኑበትም ጊዜ።'),
    'deuteronomy': BookContext(en: 'Written by Moses ~1405 BC. A series of sermons rehearsing the Law for a new generation about to enter the Promised Land.', am: 'በሙሴ የተጻፈ፣ ~1405 ዓ.ዓ. ወደ ተስፋይቱ ምድር ለሚገባ አዲስ ትውልድ ሕጉን የሚደግሙ ስብከቶች።'),
    'joshua': BookContext(en: 'Written by Joshua ~1380 BC. The conquest of Canaan — God fights for Israel as they take possession of the promised land.', am: 'በኢያሱ የተጻፈ፣ ~1380 ዓ.ዓ. የከነዓን ወረራ — እስራኤል የተስፋይቱን ምድር ሲወርሱ እግዚአብሔር ይዋጋላቸዋል።'),
    'judges': BookContext(en: 'Written by Samuel ~1020 BC. A cycle of sin, oppression, crying out, and deliverance — showing Israel\'s need for a righteous king.', am: 'በሳሙኤል የተጻፈ፣ ~1020 ዓ.ዓ. የኃጢአት፣ ጭቆና፣ ጩኸት፣ እና መዳን ዑደት — የእስራኤል የጻድቅ ንጉሥ ፍላጎት ያሳያል።'),
    'ruth': BookContext(en: 'Written by Samuel ~1000 BC. A beautiful story of loyalty, redemption, and how a Moabite widow becomes part of the lineage of Christ.', am: 'በሳሙኤል የተጻፈ፣ ~1000 ዓ.ዓ. የታማኝነት፣ የቤዛነት ታሪክ — የሞዓባዊት መበለት የክርስቶስ የትውልድ መስመር አካል እንዴት እንደምትሆን ያሳያል።'),
    '1samuel': BookContext(en: 'Written by Samuel, Nathan, Gad ~930 BC. The transition from judges to kings — Samuel, Saul\'s rise and fall, and David\'s anointing.', am: 'በሳሙኤል፣ ናታን፣ ጋድ የተጻፈ፣ ~930 ዓ.ዓ. ከመሳፍንት ወደ ነገሥታት ሽግግር — ሳሙኤል፣ የሳኦል መነሣትና መውደቅ፣ የዳዊት መቀባት።'),
    '2samuel': BookContext(en: 'Written by Samuel, Nathan, Gad ~930 BC. The reign of David — his triumphs, his sin with Bathsheba, and its consequences.', am: 'በሳሙኤል፣ ናታን፣ ጋድ የተጻፈ፣ ~930 ዓ.ዓ. የዳዊት ዘመነ መንግሥት — ድሎቹ፣ ከቤርሳቤህ ጋር ያደረገው ኃጢአት፣ ውጤቶቹ።'),
    '1kings': BookContext(en: 'Written by Jeremiah ~550 BC. Solomon\'s wisdom and temple, then the kingdom dividing into Israel and Judah.', am: 'በኤርምያስ የተጻፈ፣ ~550 ዓ.ዓ. የሰሎሞን ጥበብና ቤተ መቅደስ፣ ከዚያም መንግሥቱ ወደ እስራኤልና ይሁዳ መከፋፈል።'),
    '2kings': BookContext(en: 'Written by Jeremiah ~550 BC. The decline and fall of both kingdoms — prophets warn, exile comes as judgment for idolatry.', am: 'በኤርምያስ የተጻፈ፣ ~550 ዓ.ዓ. የሁለቱም መንግሥታት ውድቀትና ውድመት — ነቢያት ያስጠነቅቃሉ፣ ምርኮ ለጣዖት አምልኮ ፍርድ ሆኖ ይመጣል።'),
    '1chronicles': BookContext(en: 'Written by Ezra ~450 BC. A priestly perspective on Israel\'s history — focusing on David\'s dynasty and temple worship.', am: 'በእዝራ የተጻፈ፣ ~450 ዓ.ዓ. የእስራኤል ታሪክ የካህናት አተያይ — በዳዊት ሥርወ መንግሥትና በቤተ መቅደስ አምልኮ ላይ ያተኩራል።'),
    '2chronicles': BookContext(en: 'Written by Ezra ~450 BC. The history of Judah\'s kings — highlighting revivals, reforms, and God\'s faithfulness despite human failure.', am: 'በእዝራ የተጻፈ፣ ~450 ዓ.ዓ. የይሁዳ ነገሥታት ታሪክ — መነቃቃቶችን፣ ተሃድሶዎችን፣ በሰው ውድቀት መካከል የእግዚአብሔርን ታማኝነት ያጎላል።'),
    'ezra': BookContext(en: 'Written by Ezra ~440 BC. The return from exile — rebuilding the temple under Zerubbabel and spiritual renewal under Ezra.', am: 'በእዝራ የተጻፈ፣ ~440 ዓ.ዓ. ከምርኮ መመለስ — በዘሩባቤል ቤተ መቅደስን መገንባት፣ በእዝራ መንፈሳዊ እድሳት።'),
    'nehemiah': BookContext(en: 'Written by Nehemiah ~430 BC. Rebuilding Jerusalem\'s walls — leadership, opposition, and the people\'s covenant renewal.', am: 'በነህምያ የተጻፈ፣ ~430 ዓ.ዓ. የኢየሩሳሌም ቅጥር መገንባት — አመራር፣ ተቃውሞ፣ የሕዝቡ ቃል ኪዳን እድሳት።'),
    'esther': BookContext(en: 'Written by Mordecai ~460 BC. God\'s hidden providence — a Jewish queen risks her life to save her people from genocide.', am: 'በሞርዶኪ የተጻፈ፣ ~460 ዓ.ዓ. የእግዚአብሔር ስውር አመራር — አይሁዳዊት ንግሥት ሕዝቦቿን ከልቅል ለማዳን ሕይወቷን አደጋ ላይ ትጥላለች።'),
    'job': BookContext(en: 'Author unknown. A righteous man suffers terribly — exploring why the innocent suffer and God\'s sovereignty.', am: 'ጸሐፊው አይታወቅም። ጻድቅ ሰው ከባድ መከራ ይደርስበታል — ንጹሕ ሰው ለምን እንደሚያስቸግር እና የእግዚአብሔርን ሉዓላዊነት ይመረምራል።'),
    'psalms': BookContext(en: 'Written by David, Asaph, Sons of Korah, and others ~1000-400 BC. The songbook of Israel — prayers, praise, lament, and prophecy.', am: 'በዳዊት፣ አሳፍ፣ የቆራሕ ልጆች እና ሌሎች የተጻፈ፣ ~1000-400 ዓ.ዓ. የእስራኤል የዝማሬ መጽሐፍ — ጸሎት፣ ምስጋና፣ ልቅሶ፣ ትንቢት።'),
    'proverbs': BookContext(en: 'Written by Solomon and others ~950 BC. Practical wisdom for everyday life — the fear of the Lord is the beginning of knowledge.', am: 'በሰሎሞንና በሌሎች የተጻፈ፣ ~950 ዓ.ዓ. ለዕለታዊ ኑሮ ተግባራዊ ጥበብ — እግዚአብሔርን መፍራት የእውቀት መጀመሪያ ነው።'),
    'ecclesiastes': BookContext(en: 'Written by Solomon ~935 BC. A search for meaning "under the sun" — life without God is vanity, but fearing God gives purpose.', am: 'በሰሎሞን የተጻፈ፣ ~935 ዓ.ዓ. "ከፀሐይ በታች" ትርጉም ፍለጋ — ያለ እግዚአብሔር ሕይወት ከንቱ ነው፣ እግዚአብሔርን መፍራት ግን ዓላማ ይሰጣል።'),
    'songofsongs': BookContext(en: 'Written by Solomon ~950 BC. A poetic celebration of marital love — also an allegory of God\'s love for His people.', am: 'በሰሎሞን የተጻፈ፣ ~950 ዓ.ዓ. የጋብቻ ፍቅር ቅኔያዊ ክብረ በዓል — የእግዚአብሔር ለሕዝቡ ያለው ፍቅር ምሳሌም ነው።'),
    'isaiah': BookContext(en: 'Written by Isaiah ~700 BC. The greatest prophetic book — judgment on sin, the coming Messiah, and a new heavens and earth.', am: 'በኢሳይያስ የተጻፈ፣ ~700 ዓ.ዓ. ታላቁ የትንቢት መጽሐፍ — በኃጢአት ላይ ፍርድ፣ የሚመጣው መሲህ፣ አዲስ ሰማይና ምድር።'),
    'jeremiah': BookContext(en: 'Written by Jeremiah ~586 BC. The "weeping prophet" warns Judah of judgment and promises a new covenant written on the heart.', am: 'በኤርምያስ የተጻፈ፣ ~586 ዓ.ዓ. "የሚያለቅሰው ነቢይ" ይሁዳን ስለ ፍርድ ያስጠነቅቃል እና በልብ ላይ የተጻፈ አዲስ ቃል ኪዳን ተስፋ ይሰጣል።'),
    'lamentations': BookContext(en: 'Written by Jeremiah ~586 BC. Five poems of grief over Jerusalem\'s destruction — yet hope in God\'s mercies new every morning.', am: 'በኤርምያስ የተጻፈ፣ ~586 ዓ.ዓ. በኢየሩሳሌም ውድመት ላይ አምስት የሐዘን ግጥሞች — ነገር ግን በየማለዳው አዲስ በሆነው የእግዚአብሔር ምሕረት ተስፋ።'),
    'ezekiel': BookContext(en: 'Written by Ezekiel ~570 BC. Visions of God\'s glory departing and returning — judgment on Israel and the nations, then restoration.', am: 'በሕዝቅኤል የተጻፈ፣ ~570 ዓ.ዓ. የእግዚአብሔር ክብር ሲሄድና ሲመለስ ራእዮች — በእስራኤልና በአሕዛብ ላይ ፍርድ፣ ከዚያም መልሶ ማቋቋም።'),
    'daniel': BookContext(en: 'Written by Daniel ~535 BC. God\'s sovereignty over world empires — Daniel\'s faithfulness in exile and visions of the future.', am: 'በዳንኤል የተጻፈ፣ ~535 ዓ.ዓ. የእግዚአብሔር ሉዓላዊነት በዓለም መንግሥታት ላይ — የዳንኤል ታማኝነት በምርኮ እና ስለ ወደፊቱ ራእዮች።'),
    'hosea': BookContext(en: 'Written by Hosea ~715 BC. God\'s faithful love to unfaithful Israel — illustrated through the prophet\'s marriage to an unfaithful wife.', am: 'በሆሴዕ የተጻፈ፣ ~715 ዓ.ዓ. የእግዚአብሔር ታማኝ ፍቅር ለታማኝ ላልሆነች እስራኤል — በነቢዩ ጋብቻ ተመስሏል።'),
    'joel': BookContext(en: 'Written by Joel ~835 BC. A locust plague calls for repentance — God\'s mercy and the outpouring of the Spirit are promised.', am: 'በዮኤል የተጻፈ፣ ~835 ዓ.ዓ. የአንበጣ መቅሰፍት ወደ ንስሐ ይጠራል — የእግዚአብሔር ምሕረት እና የመንፈሱ መፍሰስ ተስፋ ተሰጥቷል።'),
    'amos': BookContext(en: 'Written by Amos ~750 BC. Justice, not empty religion — God despises worship without righteousness and cares for the poor.', am: 'በአሞጽ የተጻፈ፣ ~750 ዓ.ዓ. ፍትህ እንጂ ባዶ ሃይማኖት አይደለም — እግዚአብሔር ያለ ጽድቅ አምልኮን ይጠላል፣ ለድሆች ይንከባከባል።'),
    'obadiah': BookContext(en: 'Written by Obadiah ~586 BC. The shortest OT book — judgment on Edom for their pride and violence against Israel.', am: 'በአብድዩ የተጻፈ፣ ~586 ዓ.ዓ. የብሉይ ኪዳን አጭሩ መጽሐፍ — በኤዶም ላይ ፍርድ በትዕቢታቸውና በእስራኤል ላይ ባደረሱት ግፍ ምክንያት።'),
    'jonah': BookContext(en: 'Written by Jonah ~760 BC. A reluctant prophet learns that God\'s mercy extends to all nations — even Israel\'s enemies.', am: 'በዮናስ የተጻፈ፣ ~760 ዓ.ዓ. ፈቃደኛ ያልሆነ ነቢይ የእግዚአብሔር ምሕረት ለሁሉም ሕዝቦች እንደሚሆን ይማራል — የእስራኤልን ጠላቶች ጭምር።'),
    'micah': BookContext(en: 'Written by Micah ~700 BC. What God requires — to act justly, love mercy, and walk humbly with Him.', am: 'በሚክያስ የተጻፈ፣ ~700 ዓ.ዓ. እግዚአብሔር የሚፈልገው — ፍትህን ማድረግ፣ ምሕረትን መውደድ፣ ከእርሱ ጋር በትሕትና መሄድ።'),
    'nahum': BookContext(en: 'Written by Nahum ~630 BC. The fall of Nineveh — God\'s justice against evil and comfort for His oppressed people.', am: 'በናሆም የተጻፈ፣ ~630 ዓ.ዓ. የነነዌ ውድቀት — የእግዚአብሔር ፍትህ በክፋት ላይ እና ለተጨቆኑ ሕዝቦቹ ማጽናኛ።'),
    'habakkuk': BookContext(en: 'Written by Habakkuk ~600 BC. Struggling with God\'s ways — how can a just God use evil Babylon? The just shall live by faith.', am: 'በዕንባቆም የተጻፈ፣ ~600 ዓ.ዓ. ከእግዚአብሔር መንገዶች ጋር መታገል — ጻድቅ አምላክ ክፉዋን ባቢሎንን እንዴት ይጠቀማል? ጻድቅ በእምነት ይኖራል።'),
    'zephaniah': BookContext(en: 'Written by Zephaniah ~625 BC. The Day of the Lord — judgment on Judah and the nations, followed by restoration and rejoicing.', am: 'በሶፎንያስ የተጻፈ፣ ~625 ዓ.ዓ. የጌታ ቀን — በይሁዳና በአሕዛብ ላይ ፍርድ፣ ከዚያም መልሶ ማቋቋምና ደስታ።'),
    'haggai': BookContext(en: 'Written by Haggai ~520 BC. A call to rebuild God\'s house — put His kingdom first, and He will bless.', am: 'በሐጌ የተጻፈ፣ ~520 ዓ.ዓ. የእግዚአብሔርን ቤት እንደገና ለመገንባት ጥሪ — መንግሥቱን ቀድማችሁ ሥሩ፣ እርሱም ይባርካል።'),
    'zechariah': BookContext(en: 'Written by Zechariah ~520 BC. Visions of hope — the coming King, the Branch, and God\'s ultimate victory and reign.', am: 'በዘካርያስ የተጻፈ፣ ~520 ዓ.ዓ. የተስፋ ራእዮች — የሚመጣው ንጉሥ፣ ቀንዲሉ፣ የእግዚአብሔር የመጨረሻ ድልና ንግሥና።'),
    'malachi': BookContext(en: 'Written by Malachi ~430 BC. The last OT prophet — rebuking spiritual apathy and promising the coming of the Lord.', am: 'በሚልክያስ የተጻፈ፣ ~430 ዓ.ዓ. የመጨረሻው የብሉይ ኪዳን ነቢይ — መንፈሳዊ ግድየለሽነትን ይወቅሳል፣ የጌታን ምጽአት ተስፋ ይሰጣል።'),
    'matthew': BookContext(en: 'Written by Matthew ~AD 60. The Gospel to the Jews — Jesus is the promised Messiah and King, fulfilling OT prophecy.', am: 'በማቴዎስ የተጻፈ፣ ~60 ዓ.ም. ለአይሁድ ወንጌል — ኢየሱስ የተስፋው መሲህና ንጉሥ ነው፣ የብሉይ ኪዳን ትንቢትን ፈጽሟል።'),
    'mark': BookContext(en: 'Written by Mark ~AD 55. The action Gospel — Jesus as the suffering Servant, written for a Roman audience with urgency.', am: 'በማርቆስ የተጻፈ፣ ~55 ዓ.ም. የተግባር ወንጌል — ኢየሱስ እንደ መከራ አገልጋይ፣ ለሮማውያን በአስቸኳይ የተጻፈ።'),
    'luke': BookContext(en: 'Written by Luke ~AD 60. The detailed Gospel — Jesus as the Savior of all people, emphasizing prayer, the poor, and the Holy Spirit.', am: 'በሉቃስ የተጻፈ፣ ~60 ዓ.ም. ዝርዝር ወንጌል — ኢየሱስ የሁሉም ሰዎች አዳኝ፣ ጸሎትን፣ ድሆችን፣ መንፈስ ቅዱስን ያጎላል።'),
    'john': BookContext(en: 'Written by John ~AD 90. The theological Gospel — Jesus as the Son of God, with deep discourses and the "I Am" statements.', am: 'በዮሐንስ የተጻፈ፣ ~90 ዓ.ም. ሥነ መለኮታዊ ወንጌል — ኢየሱስ የእግዚአብሔር ልጅ፣ ጥልቅ ትምህርቶችና "እኔ ነኝ" የሚሉት ቃላት።'),
    'acts': BookContext(en: 'Written by Luke ~AD 62. The birth and growth of the early church — the Holy Spirit empowers witnesses from Jerusalem to Rome.', am: 'በሉቃስ የተጻፈ፣ ~62 ዓ.ም. የጥንቷ ቤተክርስቲያን ልደትና እድገት — መንፈስ ቅዱስ ከኢየሩሳሌም እስከ ሮም ምሥክሮችን ያበረታታል።'),
    'romans': BookContext(en: 'Written by Paul ~AD 57. The clearest explanation of the gospel — justification by faith, sanctification, and God\'s plan for Israel and the world.', am: 'በጳውሎስ የተጻፈ፣ ~57 ዓ.ም. የወንጌል በጣም ግልጽ ማብራሪያ — በእምነት መጽደቅ፣ መቀደስ፣ የእግዚአብሔር ዕቅድ ለእስራኤልና ለዓለም።'),
    '1corinthians': BookContext(en: 'Written by Paul ~AD 55. Correcting problems in a troubled church — division, immorality, worship, and the supremacy of love.', am: 'በጳውሎስ የተጻፈ፣ ~55 ዓ.ም. በተመሰቃቀለች ቤተክርስቲያን ውስጥ ችግሮችን መፍታት — መለያየት፣ ዝሙት፣ አምልኮ፣ የፍቅር ልዕልና።'),
    '2corinthians': BookContext(en: 'Written by Paul ~AD 56. Paul defends his apostleship — the glory of the new covenant, strength in weakness, and generous giving.', am: 'በጳውሎስ የተጻፈ፣ ~56 ዓ.ም. ጳውሎስ ሐዋርያነቱን ይከላከላል — የአዲሱ ኪዳን ክብር፣ በደካማነት ጉልበት፣ ልግስና።'),
    'galatians': BookContext(en: 'Written by Paul ~AD 49. Freedom from the law — salvation by grace alone, walking in the Spirit, and the fruit of the Spirit.', am: 'በጳውሎስ የተጻፈ፣ ~49 ዓ.ም. ከሕግ ነጻነት — በጸጋ ብቻ መዳን፣ በመንፈስ መመላለስ፣ የመንፈስ ፍሬ።'),
    'ephesians': BookContext(en: 'Written by Paul ~AD 60. Our identity in Christ — seated with Him in heavenly places, unity in the church, and spiritual warfare.', am: 'በጳውሎስ የተጻፈ፣ ~60 ዓ.ም. በክርስቶስ ያለን ማንነት — ከእርሱ ጋር በሰማያዊ ስፍራ ተቀምጠናል፣ በቤተክርስቲያን አንድነት፣ መንፈሳዊ ውጊያ።'),
    'philippians': BookContext(en: 'Written by Paul ~AD 61. Joy in every circumstance — Christ\'s humility as our pattern, pressing toward the goal, and rejoicing in the Lord.', am: 'በጳውሎስ የተጻፈ፣ ~61 ዓ.ም. በሁሉም ሁኔታ ደስታ — የክርስቶስ ትሕትና ንድፋችን፣ ወደ ዒላማው መጣር፣ በጌታ መደሰት።'),
    'colossians': BookContext(en: 'Written by Paul ~AD 61. Christ\'s supremacy over all — in creation, redemption, and daily living. Complete in Him.', am: 'በጳውሎስ የተጻፈ፣ ~61 ዓ.ም. የክርስቶስ ልዕልና በሁሉም ላይ — በፍጥረት፣ ቤዛነት፣ ዕለታዊ ኑሮ። በእርሱ ፍጹማን።'),
    '1thessalonians': BookContext(en: 'Written by Paul ~AD 51. Encouragement for a young church — holy living, love, and the hope of Christ\'s return.', am: 'በጳውሎስ የተጻፈ፣ ~51 ዓ.ም. ለወጣት ቤተክርስቲያን ማበረታቻ — ቅዱስ ኑሮ፣ ፍቅር፣ የክርስቶስ መመለስ ተስፋ።'),
    '2thessalonians': BookContext(en: 'Written by Paul ~AD 51. Correcting confusion about the end times — don\'t be idle, stand firm until the Lord comes.', am: 'በጳውሎስ የተጻፈ፣ ~51 ዓ.ም. ስለ መጨረሻው ዘመን ግራ መጋባትን መፍታት — ሥራ ፈትታችሁ አትሁኑ፣ ጌታ እስኪመለስ ድረስ ጽኑ።'),
    '1timothy': BookContext(en: 'Written by Paul ~AD 63. Instructions for church leadership — qualifications for elders, sound doctrine, and how to conduct God\'s household.', am: 'በጳውሎስ የተጻፈ፣ ~63 ዓ.ም. ለቤተክርስቲያን አመራር መመሪያዎች — የሽማግሌዎች ብቃት፣ ትክክለኛ ትምህርት፣ የእግዚአብሔርን ቤት ማስተዳደር።'),
    '2timothy': BookContext(en: 'Written by Paul ~AD 67. Paul\'s final letter — passing the torch to Timothy, endure suffering, preach the Word, finish the race.', am: 'በጳውሎስ የተጻፈ፣ ~67 ዓ.ም. የጳውሎስ የመጨረሻ ደብዳቤ — ችቦውን ለጢሞቴዎስ ማስረከብ፣ መከራን ተቀበል፣ ቃሉን ስበክ፣ ሩጫውን ጨርስ።'),
    'titus': BookContext(en: 'Written by Paul ~AD 63. Sound doctrine leads to godly living — appointing elders, teaching what is good.', am: 'በጳውሎስ የተጻፈ፣ ~63 ዓ.ም. ትክክለኛ ትምህርት ወደ እግዚአብሔርን ወደሚያስከብር ኑሮ ይመራል — ሽማግሌዎችን መሾም፣ መልካሙን ማስተማር።'),
    'philemon': BookContext(en: 'Written by Paul ~AD 61. A personal letter asking Philemon to forgive and receive back his runaway slave Onesimus as a brother.', am: 'በጳውሎስ የተጻፈ፣ ~61 ዓ.ም. ፊልሞና የሸሸውን ባሪያውን ኦንሲሞስን እንደ ወንድም ይቅር እንዲለው የሚጠይቅ የግል ደብዳቤ።'),
    'hebrews': BookContext(en: 'Author unknown ~AD 65. Christ is greater — superior to angels, Moses, and the old covenant. Hold fast to the end.', am: 'ጸሐፊው አይታወቅም፣ ~65 ዓ.ም. ክርስቶስ ይበልጣል — ከመላእክት፣ ከሙሴ፣ ከብሉይ ኪዳን ይልቅ ይበልጣል። እስከ መጨረሻ ጽኑ።'),
    'james': BookContext(en: 'Written by James (Jesus\' brother) ~AD 45. Faith that works — true religion shows itself in action, speech, and humility.', am: 'በያዕቆብ (የኢየሱስ ወንድም) የተጻፈ፣ ~45 ዓ.ም. የሚሠራ እምነት — እውነተኛ ሃይማኖት በተግባር፣ በንግግር፣ በትሕትና ይገለጣል።'),
    '1peter': BookContext(en: 'Written by Peter ~AD 64. Hope in suffering — believers are strangers in the world, called to holiness and standing firm in grace.', am: 'በጴጥሮስ የተጻፈ፣ ~64 ዓ.ም. በመከራ ውስጥ ተስፋ — አማኞች በዓለም እንግዶች ናቸው፣ ወደ ቅድስናና በጸጋ ጽናት የተጠሩ።'),
    '2peter': BookContext(en: 'Written by Peter ~AD 66. Grow in grace — guard against false teachers, remember Christ\'s return, and add to your faith.', am: 'በጴጥሮስ የተጻፈ፣ ~66 ዓ.ም. በጸጋ እደጉ — ከሐሰተኛ አስተማሪዎች ተጠንቀቁ፣ የክርስቶስን መመለስ አስታውሱ፣ በእምነታችሁ ላይ ጨምሩ።'),
    '1john': BookContext(en: 'Written by John ~AD 90. Walking in the light — tests of genuine faith, love for the brethren, and confidence in God.', am: 'በዮሐንስ የተጻፈ፣ ~90 ዓ.ም. በብርሃን መሄድ — የእውነተኛ እምነት ፈተናዎች፣ ለወንድሞች ፍቅር፣ በእግዚአብሔር መታመን።'),
    '2john': BookContext(en: 'Written by John ~AD 90. Walk in truth and love — do not welcome false teachers into your home.', am: 'በዮሐንስ የተጻፈ፣ ~90 ዓ.ም. በእውነትና በፍቅር ሂዱ — ሐሰተኛ አስተማሪዎችን ወደ ቤታችሁ አትቀበሉ።'),
    '3john': BookContext(en: 'Written by John ~AD 90. Commending hospitality — support fellow workers for the truth and imitate good, not evil.', am: 'በዮሐንስ የተጻፈ፣ ~90 ዓ.ም. እንግዳ መቀበልን ማሞገስ — የእውነት ሠራተኞችን ደግፉ፣ መልካሙን እንጂ ክፉውን አትምሰሉ።'),
    'jude': BookContext(en: 'Written by Jude (Jesus\' brother) ~AD 65. Contend for the faith — against false teachers who pervert grace into license.', am: 'በይሁዳ (የኢየሱስ ወንድም) የተጻፈ፣ ~65 ዓ.ም. ለእምነት ታገሉ — ጸጋን ወደ ፈቃደኛነት በሚለውጡ ሐሰተኛ አስተማሪዎች ላይ።'),
    'revelation': BookContext(en: 'Written by John ~AD 95. The unveiling of Jesus Christ — the triumph of the Lamb, judgment on evil, a new heaven and earth.', am: 'በዮሐንስ የተጻፈ፣ ~95 ዓ.ም. የኢየሱስ ክርስቶስ መገለጥ — የበጉ ድል፣ በክፋት ላይ ፍርድ፣ አዲስ ሰማይና ምድር።'),
  };

  static String getContext(String bookId, bool isAm) {
    final ctx = books[bookId];
    if (ctx == null) return '';
    return isAm ? ctx.am : ctx.en;
  }

  static ({String bigIdeaEn, String bigIdeaAm, String questionEn, String questionAm}) forDay(int day, String planId) {
    final generic = _genericEntries[day % _genericEntries.length];
    return (
      bigIdeaEn: generic.bigIdeaEn,
      bigIdeaAm: generic.bigIdeaAm,
      questionEn: generic.questionEn,
      questionAm: generic.questionAm,
    );
  }
}

class _GenericEntry {
  final String bigIdeaEn, bigIdeaAm, questionEn, questionAm;
  const _GenericEntry({required this.bigIdeaEn, required this.bigIdeaAm, required this.questionEn, required this.questionAm});
}

const List<_GenericEntry> _genericEntries = [
  _GenericEntry(bigIdeaEn: 'God speaks through His Word — listen carefully to what He is saying today.', bigIdeaAm: 'እግዚአብሔር በቃሉ ይናገራል — ዛሬ የሚለውን በጥንቃቄ አዳምጥ።', questionEn: 'What stood out to you most in this passage?', questionAm: 'በዚህ ምንባብ ውስጥ በጣም የሚስብህ ምንድን ነው?'),
  _GenericEntry(bigIdeaEn: 'Scripture reveals God\'s character — He is faithful, just, and loving.', bigIdeaAm: 'ቃሉ የእግዚአብሔርን ባሕርይ ይገልጣል — እርሱ ታማኝ፣ ጻድቅ፣ አፍቃሪ ነው።', questionEn: 'What does this chapter teach you about God\'s character?', questionAm: 'ይህ ምዕራፍ ስለ እግዚአብሔር ባሕርይ ምን ያስተምራል?'),
  _GenericEntry(bigIdeaEn: 'God\'s Word is living and active — it speaks into your specific situation today.', bigIdeaAm: 'የእግዚአብሔር ቃል ሕያውና ውጤታማ ነው — ዛሬ ወደ ልዩ ሁኔታህ ይናገራል።', questionEn: 'How does this passage apply to something you are facing right now?', questionAm: 'ይህ ምንባብ አሁን ከምትጋፈጠው ነገር ጋር እንዴት ይዛመዳል?'),
  _GenericEntry(bigIdeaEn: 'Obedience to God flows from trust in His character and promises.', bigIdeaAm: 'ለእግዚአብሔር መታዘዝ የሚመነጨው በባሕርዩና በተስፋዎቹ ከማመን ነው።', questionEn: 'Is there an area where God is calling you to obey — even if it\'s hard?', questionAm: 'እግዚአብሔር ልትታዘዘው የሚጠራህ ቦታ አለ — ከባድ ቢሆንም?'),
  _GenericEntry(bigIdeaEn: 'God\'s faithfulness in the past gives confidence for the future.', bigIdeaAm: 'የእግዚአብሔር ያለፈ ታማኝነት ለወደፊቱ እምነት ይሰጣል።', questionEn: 'How has God been faithful to you this week?', questionAm: 'እግዚአብሔር በዚህ ሳምንት ለአንተ ታማኝ የነበረው እንዴት ነው?'),
  _GenericEntry(bigIdeaEn: 'Prayer is our response to God\'s Word — talk to Him about what you read.', bigIdeaAm: 'ጸሎት ለእግዚአብሔር ቃል የምንሰጠው ምላሽ ነው — ያነበብከውን አነጋግረው።', questionEn: 'Turn what you just read into a prayer — what do you want to say to God?', questionAm: 'ያነበብከውን ወደ ጸሎት ቀይር — ለእግዚአብሔር ምን ማለት ትፈልጋለህ?'),
];
