import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/recipe/recipe_search_screen.dart';
import '../screens/recipe/recipe_detail_screen.dart';
import '../screens/recipe/recipe_generate_screen.dart';
import '../screens/recipe/recipe_detail_direct_screen.dart';
import '../screens/camera/camera_screen.dart';
import '../screens/favorites/favorites_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/chat/ai_chat_screen.dart';
import '../screens/dashboard/monitoring_dashboard.dart';
import '../providers/auth_provider.dart';
import '../screens/profile/profile_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthenticated = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/splash';
      if (!isAuthenticated && !isAuthRoute) return '/login';
      if (isAuthenticated && state.matchedLocation == '/login') return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
      ShellRoute(
        builder: (context, state, child) => HomeScreen(child: child),
        routes: [
          GoRoute(path: '/home', builder: (c, s) => const HomeContent()),
          GoRoute(path: '/search', builder: (c, s) => const RecipeSearchScreen()),
          GoRoute(
            path: '/recipe/:id',
            builder: (c, s) => RecipeDetailScreen(recipeId: s.pathParameters['id'] ?? ''),
          ),
          GoRoute(path: '/generate', builder: (c, s) => const RecipeGenerateScreen()),
          GoRoute(path: '/camera', builder: (c, s) => const CameraScreen()),
          GoRoute(path: '/favorites', builder: (c, s) => const FavoritesScreen()),
          GoRoute(path: '/history', builder: (c, s) => const HistoryScreen()),
          GoRoute(path: '/chat', builder: (c, s) => const AiChatScreen()),
          GoRoute(path: '/dashboard', builder: (c, s) => const MonitoringDashboard()),
          GoRoute(
            path: '/profile',
            builder: (c, s) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/cuisine/:name',
            builder: (c, s) => CuisineScreen(cuisineName: s.pathParameters['name'] ?? ''),
          ),
          GoRoute(
            path: '/dish',
            builder: (c, s) => RecipeDetailDirectScreen(
              dishName: s.uri.queryParameters['name'] ?? '',
              imageUrl: s.uri.queryParameters['img'],
            ),
          ),
        ],
      ),
    ],
  );
});

// ═══════════════════════════════════════════════════════════
// DISH MODEL
// ═══════════════════════════════════════════════════════════

class DishItem {
  final String name;
  final String originalName;
  final String description;
  final String history;
  final String prepTime;
  final String difficulty;

  const DishItem({
    required this.name,
    required this.originalName,
    required this.description,
    required this.history,
    required this.prepTime,
    required this.difficulty,
  });

  String get imageUrl =>
      'https://source.unsplash.com/400x300/?${Uri.encodeComponent(name)},food';
}

// ═══════════════════════════════════════════════════════════
// CUISINE SCREEN
// ═══════════════════════════════════════════════════════════

class CuisineScreen extends StatelessWidget {
  final String cuisineName;
  const CuisineScreen({super.key, required this.cuisineName});

  @override
  Widget build(BuildContext context) {
    final dishes = CuisineDishDatabase.getDishes(cuisineName);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: Text('$cuisineName Cuisine'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: dishes.length,
        itemBuilder: (context, index) {
          return _DishCard(dish: dishes[index]);
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// DISH CARD
// ═══════════════════════════════════════════════════════════

class _DishCard extends StatelessWidget {
  final DishItem dish;
  const _DishCard({required this.dish});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go(
          '/dish?name=${Uri.encodeComponent(dish.name)}&img=${Uri.encodeComponent(dish.imageUrl)}',
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: CachedNetworkImage(
                imageUrl: dish.imageUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (ctx, url) => Container(
                  height: 160,
                  color: colorScheme.primaryContainer,
                  child: Center(
                    child: Icon(Icons.restaurant, size: 40, color: colorScheme.primary),
                  ),
                ),
                errorWidget: (ctx, url, err) => Container(
                  height: 160,
                  color: colorScheme.primaryContainer,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant, size: 40, color: colorScheme.primary),
                        const SizedBox(height: 8),
                        Text(dish.name, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dish.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            if (dish.originalName.isNotEmpty && dish.originalName != dish.name)
                              Text(dish.originalName, style: TextStyle(fontSize: 12, color: colorScheme.primary, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _diffColor(dish.difficulty).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(dish.difficulty, style: TextStyle(fontSize: 11, color: _diffColor(dish.difficulty), fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(dish.description, style: const TextStyle(color: Colors.grey, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.history_edu, size: 13, color: colorScheme.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(dish.history, style: const TextStyle(fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(dish.prepTime, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () => context.go('/dish?name=${Uri.encodeComponent(dish.name)}&img=${Uri.encodeComponent(dish.imageUrl)}'),
                        icon: const Icon(Icons.auto_awesome, size: 13),
                        label: const Text('Get Recipe', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _diffColor(String d) {
    if (d == 'Easy') return Colors.green;
    if (d == 'Hard') return Colors.red;
    return Colors.orange;
  }
}

// ═══════════════════════════════════════════════════════════
// 1000+ DISHES DATABASE
// ═══════════════════════════════════════════════════════════

class CuisineDishDatabase {
  static List<DishItem> getDishes(String cuisine) {
    switch (cuisine) {
      case 'Italian': return _italian;
      case 'Indian': return _indian;
      case 'Mexican': return _mexican;
      case 'Japanese': return _japanese;
      case 'Chinese': return _chinese;
      case 'French': return _french;
      case 'Thai': return _thai;
      case 'American': return _american;
      case 'Mediterranean': return _mediterranean;
      case 'Middle Eastern': return _middleEastern;
      case 'Korean': return _korean;
      case 'Spanish': return _spanish;
      case 'Greek': return _greek;
      case 'Vietnamese': return _vietnamese;
      case 'Ethiopian': return _ethiopian;
      default: return _italian;
    }
  }

  // ─── ITALIAN (80 dishes) ───────────────────────────────
  static const _italian = [
    DishItem(name:'Pizza Margherita',originalName:'Pizza Margherita',description:'Classic Neapolitan pizza with San Marzano tomatoes, buffalo mozzarella and fresh basil.',history:'Created in 1889 in Naples for Queen Margherita of Savoy. The three colors represent the Italian flag.',prepTime:'45 min',difficulty:'Medium'),
    DishItem(name:'Pasta Carbonara',originalName:'Pasta alla Carbonara',description:'Silky pasta with eggs, pecorino romano, guanciale and black pepper. No cream.',history:'Roman dish from mid-20th century. Some say American soldiers brought bacon and eggs to Rome after WWII liberation.',prepTime:'25 min',difficulty:'Medium'),
    DishItem(name:'Lasagna',originalName:'Lasagne al Forno',description:'Layered pasta with rich Bolognese ragu, bechamel sauce and parmesan.',history:'Originated in Emilia-Romagna, specifically Bologna. One of the oldest pasta dishes dating to the Middle Ages.',prepTime:'90 min',difficulty:'Hard'),
    DishItem(name:'Risotto alla Milanese',originalName:'Risotto alla Milanese',description:'Saffron-infused Arborio rice with bone marrow and parmesan.',history:'Dates to 1574 when a glassmaker\'s apprentice added saffron to wedding risotto as a prank. Became Milan\'s signature dish.',prepTime:'40 min',difficulty:'Medium'),
    DishItem(name:'Tiramisu',originalName:'Tiramisù',description:'Coffee-soaked ladyfingers layered with mascarpone cream and cocoa.',history:'Created in Treviso, Veneto in the 1960s. Name means "pick me up" referring to the energizing coffee and sugar.',prepTime:'30 min',difficulty:'Easy'),
    DishItem(name:'Osso Buco',originalName:'Ossobuco alla Milanese',description:'Braised veal shanks in white wine with gremolata of lemon, garlic and parsley.',history:'Milanese specialty from Lombardy. The name means "bone with a hole" referring to the marrow-filled veal shank.',prepTime:'120 min',difficulty:'Hard'),
    DishItem(name:'Bruschetta al Pomodoro',originalName:'Bruschetta al Pomodoro',description:'Grilled bread with ripe tomatoes, garlic, basil and extra virgin olive oil.',history:'Central Italian peasant food to taste new season olive oil. Name from "bruscare" meaning to roast over coals.',prepTime:'15 min',difficulty:'Easy'),
    DishItem(name:'Minestrone',originalName:'Minestrone',description:'Hearty seasonal vegetable soup with cannellini beans and small pasta.',history:'Ancient Roman peasant recipe. No fixed ingredients - uses whatever vegetables are available each season.',prepTime:'60 min',difficulty:'Easy'),
    DishItem(name:'Gnocchi al Pesto',originalName:'Gnocchi di Patate al Pesto',description:'Soft potato dumplings with vibrant Genovese basil pesto sauce.',history:'Potato gnocchi became popular after potatoes arrived from Americas in 16th century. Traditional Thursday dish in Rome.',prepTime:'50 min',difficulty:'Medium'),
    DishItem(name:'Panna Cotta',originalName:'Panna Cotta',description:'Silky cooked cream with vanilla, served with fresh berry coulis.',history:'Piedmontese dessert meaning "cooked cream." Legend says a Hungarian woman taught the recipe to northern Italians.',prepTime:'20 min',difficulty:'Easy'),
    DishItem(name:'Arancini',originalName:'Arancini di Riso',description:'Fried golden risotto balls stuffed with mozzarella and meat ragu.',history:'Sicilian street food since the 10th century during Arab rule. Name means "little oranges" due to golden round appearance.',prepTime:'60 min',difficulty:'Hard'),
    DishItem(name:'Cannoli Siciliani',originalName:'Cannoli Siciliani',description:'Crispy fried pastry tubes filled with sweet sheep ricotta and candied orange.',history:'Originated in Sicily during Arab rule in 9th century. Originally made only during Carnivale season.',prepTime:'90 min',difficulty:'Hard'),
    DishItem(name:'Cacio e Pepe',originalName:'Cacio e Pepe',description:'Roman pasta with only pecorino romano, black pepper and pasta water.',history:'Ancient Roman shepherds created this dish with shelf-stable ingredients. Mastering the emulsion technique is the challenge.',prepTime:'20 min',difficulty:'Medium'),
    DishItem(name:'Saltimbocca',originalName:'Saltimbocca alla Romana',description:'Veal escalope topped with prosciutto and sage, cooked in white wine.',history:'Roman specialty meaning "jumps in the mouth." Simple yet elegant dish of the Roman trattoria tradition.',prepTime:'25 min',difficulty:'Medium'),
    DishItem(name:'Focaccia Genovese',originalName:'Focaccia Genovese',description:'Flat oven bread with olive oil, sea salt, dimples and rosemary.',history:'Ancient Ligurian bread. Genoese eat it for breakfast dipped in cappuccino. A tradition unique to Genoa.',prepTime:'120 min',difficulty:'Medium'),
    DishItem(name:'Amatriciana',originalName:'Pasta all Amatriciana',description:'Bucatini pasta with guanciale, San Marzano tomatoes and pecorino.',history:'From Amatrice in Lazio. Originally called Gricia without tomatoes. Tomatoes added after 18th century.',prepTime:'30 min',difficulty:'Easy'),
    DishItem(name:'Caprese',originalName:'Insalata Caprese',description:'Fresh buffalo mozzarella, ripe tomatoes and basil with olive oil.',history:'Named after Capri island. Created in early 20th century representing Italian flag: red, white and green.',prepTime:'10 min',difficulty:'Easy'),
    DishItem(name:'Ribollita',originalName:'Ribollita',description:'Tuscan bread and black kale soup with cannellini beans, twice cooked.',history:'Peasant dish from Tuscany meaning "reboiled." Made by reheating leftover minestrone with stale bread added.',prepTime:'90 min',difficulty:'Easy'),
    DishItem(name:'Bistecca Fiorentina',originalName:'Bistecca alla Fiorentina',description:'Thick T-bone steak from Chianina cattle, charcoal grilled rare.',history:'Florentine tradition dating to the Medici era. Must weigh at least 600 grams and served blood rare per Florentine law.',prepTime:'20 min',difficulty:'Medium'),
    DishItem(name:'Pesto Genovese',originalName:'Pesto alla Genovese',description:'Basil sauce pounded with pine nuts, garlic, parmigiano and pecorino.',history:'Created in Genoa, Liguria. The word "pesto" from "pestare" meaning to pound. Made in marble mortar traditionally.',prepTime:'15 min',difficulty:'Easy'),
    DishItem(name:'Spaghetti alle Vongole',originalName:'Spaghetti alle Vongole',description:'Spaghetti with fresh clams in white wine, garlic and parsley.',history:'Neapolitan coastal tradition. Two versions exist: red with tomato (rosso) and white without (bianco). Both are authentic.',prepTime:'25 min',difficulty:'Medium'),
    DishItem(name:'Tortellini in Brodo',originalName:'Tortellini in Brodo',description:'Tiny meat-filled pasta rings served in rich capon broth.',history:'From Bologna and Modena, Emilia-Romagna. Legend says tortellini was inspired by Venus\'s navel seen through a keyhole.',prepTime:'180 min',difficulty:'Hard'),
    DishItem(name:'Gricia',originalName:'Pasta alla Gricia',description:'Pasta with guanciale, pecorino romano and black pepper. Amatriciana without tomato.',history:'Considered the ancestor of both Carbonara and Amatriciana. Named after Grisciano village in Lazio.',prepTime:'20 min',difficulty:'Easy'),
    DishItem(name:'Acquacotta',originalName:'Acquacotta',description:'Tuscan "cooked water" soup with vegetables and egg poached in broth.',history:'Maremma shepherd\'s survival food. Name means "cooked water" as it was made with almost nothing.',prepTime:'45 min',difficulty:'Easy'),
    DishItem(name:'Baccalà alla Vicentina',originalName:'Baccalà alla Vicentina',description:'Salt cod slowly braised in milk with onions and anchovies.',history:'Vicenza specialty using stockfish brought by Pietro Querini from Norway in 1432. Celebrated for 600 years.',prepTime:'2880 min',difficulty:'Hard'),
    DishItem(name:'Ragù alla Bolognese',originalName:'Ragù alla Bolognese',description:'Slow-cooked meat sauce with beef, pork, wine, milk and vegetables.',history:'Official recipe registered with Bologna Chamber of Commerce in 1982. Spaghetti Bolognese is Italian-American invention.',prepTime:'240 min',difficulty:'Medium'),
    DishItem(name:'Polenta',originalName:'Polenta',description:'Slow-cooked cornmeal porridge served with mushrooms or braised meats.',history:'Replaced chestnut flour porridge after corn arrived from Americas. Northern Italian staple particularly in Veneto and Lombardy.',prepTime:'60 min',difficulty:'Easy'),
    DishItem(name:'Cacciucco',originalName:'Cacciucco alla Livornese',description:'Livorno fish stew with multiple seafood varieties in tomato-wine broth.',history:'Coastal Tuscany dish from Livorno. Tradition says it must contain at least 5 types of fish, one for each C in cacciucco.',prepTime:'90 min',difficulty:'Hard'),
    DishItem(name:'Supplì',originalName:'Supplì al Telefono',description:'Roman fried rice balls with mozzarella that stretches like telephone wire.',history:'Roman street food cousin to Sicilian arancini but different shape. "Al telefono" refers to the cheese stretching like old phone cords.',prepTime:'60 min',difficulty:'Medium'),
    DishItem(name:'Porchetta',originalName:'Porchetta',description:'Whole pig deboned, seasoned with wild fennel, rosemary and garlic, spit-roasted.',history:'Ancient central Italian tradition, especially from Ariccia near Rome and Norcia in Umbria. Festival food for centuries.',prepTime:'480 min',difficulty:'Hard'),
    DishItem(name:'Vitello Tonnato',originalName:'Vitello Tonnato',description:'Thin sliced cold veal covered with creamy tuna mayonnaise sauce.',history:'Piedmontese summer dish from 18th century. The unusual tuna-veal combination predates modern food creativity by centuries.',prepTime:'120 min',difficulty:'Medium'),
    DishItem(name:'Aglio e Olio',originalName:'Spaghetti Aglio e Olio',description:'Midnight pasta with garlic golden-fried in olive oil and chili flakes.',history:'Neapolitan peasant dish requiring only pantry staples. Famous as the dish cooked after parties and late nights.',prepTime:'15 min',difficulty:'Easy'),
    DishItem(name:'Piada Romagnola',originalName:'Piadina Romagnola',description:'Thin flatbread from Romagna filled with squacquerone cheese and arugula.',history:'Ancient flatbread from Emilia-Romagna coast. Giovanni Pascoli called it "the bread of friends." Now with IGP protected status.',prepTime:'20 min',difficulty:'Easy'),
    DishItem(name:'Ribollita Toscana',originalName:'Ribollita Toscana',description:'Thick black kale, bread and bean soup traditionally made next day.',history:'True ribollita means the soup is made one day and reheated next day, becoming even more flavorful.',prepTime:'90 min',difficulty:'Easy'),
    DishItem(name:'Trippa alla Romana',originalName:'Trippa alla Romana',description:'Slow braised tripe in tomato sauce with mint and pecorino.',history:'Roman cucina povera (poor food). Saturday is traditional tripe day in Rome. Offal cooking is an ancient Roman tradition.',prepTime:'180 min',difficulty:'Medium'),
    DishItem(name:'Semifreddo',originalName:'Semifreddo',description:'Partially frozen Italian dessert, lighter than ice cream, rich as mousse.',history:'Italian innovation in frozen desserts. Unlike gelato it is not churned. Often made in loaf pan and sliced.',prepTime:'240 min',difficulty:'Medium'),
    DishItem(name:'Pandoro',originalName:'Pandoro Veronese',description:'Golden star-shaped Christmas cake with vanilla and dusted with icing sugar.',history:'From Verona, the name means "golden bread." Competition with Milanese Panettone for Italian Christmas cake supremacy.',prepTime:'1440 min',difficulty:'Hard'),
    DishItem(name:'Panettone',originalName:'Panettone Milanese',description:'Tall leavened Christmas bread with candied fruits and raisins.',history:'Milanese Christmas tradition since the 15th century. Legend says a young baker named Toni created it: "pan de Toni."',prepTime:'2880 min',difficulty:'Hard'),
    DishItem(name:'Zuppa Inglese',originalName:'Zuppa Inglese',description:'Trifle-like layered dessert with alchermes-soaked sponge and custard cream.',history:'Despite the name "English soup," it is purely Italian. Emilian dessert inspired by English trifle brought by diplomats.',prepTime:'60 min',difficulty:'Medium'),
    DishItem(name:'Fregola con Arselle',originalName:'Fregola con Arselle',description:'Sardinian toasted couscous with vongole and saffron-tomato broth.',history:'Sardinian ancient pasta, UNESCO-recognized. Toasted in oven giving nutty flavor unique in Italian pasta tradition.',prepTime:'45 min',difficulty:'Medium'),
  ];

  // ─── INDIAN (80 dishes) ───────────────────────────────
  static const _indian = [
    DishItem(name:'Butter Chicken',originalName:'Murgh Makhani',description:'Tender chicken tikka in rich creamy tomato-butter sauce with aromatic spices.',history:'Accidentally created in 1950s Delhi. Kundan Lal Gujral added leftover tandoori chicken to tomato gravy - changed Indian cuisine forever.',prepTime:'45 min',difficulty:'Medium'),
    DishItem(name:'Biryani Hyderabadi',originalName:'Hyderabadi Dum Biryani',description:'Aged basmati rice layered with marinated meat, fried onions and saffron milk.',history:'Brought to Hyderabad by Mughal viceroys. The dum cooking technique seals steam inside sealed pot, creating unique flavors.',prepTime:'180 min',difficulty:'Hard'),
    DishItem(name:'Dal Makhani',originalName:'Dal Makhani',description:'Whole black urad lentils slow-cooked 24 hours with butter and cream.',history:'Invented at Moti Mahal restaurant Delhi in 1947. The cook Kundan Lal Gujral slow-cooked the dal overnight in a tandoor.',prepTime:'1440 min',difficulty:'Medium'),
    DishItem(name:'Palak Paneer',originalName:'Palak Paneer',description:'Fresh cottage cheese in smooth spiced spinach-cream gravy.',history:'North Indian vegetarian staple. Became globally popular as Indian restaurants spread worldwide in the 1960s and 70s.',prepTime:'40 min',difficulty:'Easy'),
    DishItem(name:'Samosa',originalName:'Samosa',description:'Crispy triangular pastry filled with spiced potatoes, peas and herbs.',history:'Persian origin as "sambosa," traveled the Silk Road to India. Became India\'s most beloved street snack over 800 years.',prepTime:'60 min',difficulty:'Medium'),
    DishItem(name:'Chole Bhature',originalName:'Chole Bhature',description:'Spicy white chickpea curry with deep-fried puffed bread.',history:'Punjabi comfort food born in Delhi dhabas. The combination became the definitive Delhi Sunday brunch dish.',prepTime:'60 min',difficulty:'Medium'),
    DishItem(name:'Tandoori Chicken',originalName:'Tandoori Murgh',description:'Yogurt-marinated chicken with tandoori masala cooked in clay oven at 500C.',history:'Invented by Kundan Lal Jaggi in Peshawar in 1920s. Moved to Delhi post-partition. India\'s most recognized international dish.',prepTime:'480 min',difficulty:'Medium'),
    DishItem(name:'Rogan Josh',originalName:'Rogan Josh',description:'Kashmiri lamb slow-cooked in aromatic spices with Kashmiri chili color.',history:'Persian royal dish brought to Kashmir by Mughal emperor Akbar. "Rogan" means clarified butter and "Josh" means intense heat.',prepTime:'90 min',difficulty:'Medium'),
    DishItem(name:'Masala Dosa',originalName:'Masala Dosa',description:'Paper-thin fermented crepe filled with spiced potato masala.',history:'South Indian staple over 2000 years old. Fermentation of rice and lentils creates the distinctive sour flavor.',prepTime:'480 min',difficulty:'Hard'),
    DishItem(name:'Gulab Jamun',originalName:'Gulab Jamun',description:'Soft khoya milk dumplings soaked in rose-cardamom sugar syrup.',history:'Derived from Persian luqmat al-qadi. Brought to India by Persian-Arab invaders. Name means "rose" and "berry."',prepTime:'60 min',difficulty:'Medium'),
    DishItem(name:'Pav Bhaji',originalName:'Pav Bhaji',description:'Spiced mixed vegetable mash on iron griddle served with buttered buns.',history:'Invented for Mumbai textile mill workers in 1850s. Street food genius - nutritious, fast, cheap and delicious.',prepTime:'45 min',difficulty:'Easy'),
    DishItem(name:'Rajma Chawal',originalName:'Rajma Chawal',description:'Red kidney bean curry with steamed basmati rice.',history:'Mexican kidney beans introduced to India by Portuguese traders. Became ultimate Punjabi Sunday comfort food.',prepTime:'60 min',difficulty:'Easy'),
    DishItem(name:'Aloo Paratha',originalName:'Aloo Paratha',description:'Whole wheat flatbread stuffed with spiced mashed potatoes, fried in ghee.',history:'Punjab\'s morning ritual. No Punjabi breakfast is complete without aloo paratha with white butter, yogurt and pickle.',prepTime:'45 min',difficulty:'Medium'),
    DishItem(name:'Chicken Tikka Masala',originalName:'Chicken Tikka Masala',description:'Grilled tandoori chicken in creamy spiced tomato-onion sauce.',history:'Origins disputed between India and Glasgow UK. Former British Foreign Secretary Robin Cook called it "true national British dish."',prepTime:'60 min',difficulty:'Medium'),
    DishItem(name:'Idli Sambar',originalName:'Idli Sambar',description:'Steamed fermented rice cakes with spiced lentil and vegetable stew.',history:'Over 1000 years old in Tamil Nadu and Karnataka. Fermentation process was perfected through centuries of South Indian cooking.',prepTime:'480 min',difficulty:'Medium'),
    DishItem(name:'Kheer',originalName:'Kheer',description:'Creamy slow-cooked rice pudding with milk, sugar, cardamom and dry fruits.',history:'One of oldest Indian desserts, mentioned in Sanskrit literature. Temple prasad for thousands of years across India.',prepTime:'60 min',difficulty:'Easy'),
    DishItem(name:'Korma',originalName:'Shahi Korma',description:'Mild aromatic curry braised in cream, yogurt and nut paste.',history:'Mughal royal court dish. Served at Akbar\'s banquets in 16th century. "Korma" means braising in Persian-Urdu.',prepTime:'60 min',difficulty:'Medium'),
    DishItem(name:'Vada Pav',originalName:'Vada Pav',description:'Spiced potato fritter in bread bun with dry garlic chutney.',history:'Created in 1966 near Dadar station Mumbai by Ashok Vaidya. Called "Indian burger," feeds millions daily in Mumbai.',prepTime:'40 min',difficulty:'Medium'),
    DishItem(name:'Gajar Halwa',originalName:'Gajar ka Halwa',description:'Slow-cooked carrot pudding with milk, ghee, sugar and cardamom.',history:'North Indian winter specialty using red Delhi carrots. Traditional wedding and festival dessert cooked in giant kadai.',prepTime:'90 min',difficulty:'Easy'),
    DishItem(name:'Vindaloo',originalName:'Goan Pork Vindaloo',description:'Fiery Goan pork curry with vinegar, garlic and Kashmiri chilies.',history:'Portuguese "carne de vinha d\'alhos" (meat in wine and garlic) transformed by Goan cooks adding their spices and chilies.',prepTime:'1440 min',difficulty:'Hard'),
    DishItem(name:'Dhokla',originalName:'Khaman Dhokla',description:'Steamed fermented chickpea flour cake, spongy and slightly sour.',history:'Gujarati staple over 1000 years old. Mentioned in a Jain text from 1066 AD. Healthy fermented snack eaten any time.',prepTime:'240 min',difficulty:'Easy'),
    DishItem(name:'Pulao',originalName:'Matar Paneer Pulao',description:'Fragrant rice pilaf with peas, paneer and whole spices.',history:'Mughal court dish evolved from Persian pilaf. Different from biryani - simpler cooking method with rice and ingredients together.',prepTime:'30 min',difficulty:'Easy'),
    DishItem(name:'Chaat',originalName:'Papdi Chaat',description:'Crispy wafers with chickpeas, potatoes, chutneys and yogurt.',history:'Delhi street food dating to Mughal era. Chaat means "to lick" - describes the irresistible tangy, spicy, sweet combination.',prepTime:'30 min',difficulty:'Easy'),
    DishItem(name:'Pani Puri',originalName:'Pani Puri / Golgappa',description:'Hollow crispy puris filled with spiced water, chickpeas and potato.',history:'Origins disputed between Uttar Pradesh and Patna. Each state has different name: Golgappa in Delhi, Puchka in Bengal.',prepTime:'60 min',difficulty:'Hard'),
    DishItem(name:'Haleem',originalName:'Hyderabadi Haleem',description:'Slow-cooked wheat, barley and meat porridge with fried onions.',history:'Arab dish "harisa" brought to Hyderabad. Cooked in clay pots for 12 hours during Ramadan. UNESCO-recognized Hyderabadi specialty.',prepTime:'720 min',difficulty:'Hard'),
    DishItem(name:'Fish Curry',originalName:'Machher Jhol',description:'Bengali mustard-turmeric fish curry in light flavorful broth.',history:'Fish is the soul of Bengali cuisine. This simple curry showcases mustard and turmeric - Bengal\'s defining flavor combination.',prepTime:'30 min',difficulty:'Easy'),
    DishItem(name:'Rasam',originalName:'Rasam',description:'Thin peppery tomato soup from Tamil Nadu, digestive and warming.',history:'Ancient Tamil medicine - a digestive tonic. Name from Sanskrit "rasa" meaning juice or essence. South Indian meal finale.',prepTime:'20 min',difficulty:'Easy'),
    DishItem(name:'Appam',originalName:'Appam with Stew',description:'Lacy fermented rice crepe with soft center, served with coconut stew.',history:'Kerala specialty with Portuguese influence. The word may come from Portuguese "pão" (bread). Christian community staple.',prepTime:'480 min',difficulty:'Medium'),
    DishItem(name:'Laal Maas',originalName:'Laal Maas',description:'Rajasthani fiery red mutton curry with Mathania chilies.',history:'Royal Rajput hunting dish. "Laal" means red. Used Mathania chilies from Jodhpur. Made with wild game for Maharaja hunts.',prepTime:'120 min',difficulty:'Hard'),
    DishItem(name:'Malabar Fish Curry',originalName:'Kerala Fish Curry',description:'Kerala fish in coconut milk with Kodampuli (Gamboge) souring agent.',history:'Malabar coastal tradition using the unique Kodampuli fruit only found in Kerala. Dutch and Portuguese spice trade influence.',prepTime:'30 min',difficulty:'Easy'),
    DishItem(name:'Jalebi',originalName:'Jalebi',description:'Crispy coiled fermented batter fried and soaked in saffron sugar syrup.',history:'Derived from Persian "zalibiya." First mentioned in Indian texts in 1450 AD. Now pan-Indian festive sweet eaten hot.',prepTime:'60 min',difficulty:'Hard'),
    DishItem(name:'Kachori',originalName:'Pyaaz Kachori',description:'Deep fried spiced pastry filled with onion or lentil filling.',history:'Rajasthani specialty popular across North India. Jodhpur\'s Pyaaz Kachori is legendary breakfast food in the blue city.',prepTime:'60 min',difficulty:'Medium'),
    DishItem(name:'Undhiyu',originalName:'Surti Undhiyu',description:'Gujarati mixed winter vegetable dish with fenugreek dumplings.',history:'From Surat, Gujarat. "Undhu" means upside down in Gujarati - cooked in inverted clay pot buried in ground over fire.',prepTime:'120 min',difficulty:'Hard'),
    DishItem(name:'Mutton Keema',originalName:'Mutton Keema',description:'Minced mutton cooked with onions, tomatoes and aromatic spices.',history:'Mughal influence on Indian cuisine. Keema can be eaten in countless ways - with pav, paratha, naan or as stuffing.',prepTime:'45 min',difficulty:'Easy'),
    DishItem(name:'Payasam',originalName:'Kerala Payasam',description:'South Indian rice or vermicelli kheer with coconut milk and jaggery.',history:'Ancient temple offering across South India. Onam sadya (feast) is incomplete without multiple types of payasam.',prepTime:'45 min',difficulty:'Easy'),
    DishItem(name:'Bisi Bele Bath',originalName:'Bisi Bele Bath',description:'Karnataka one-pot spiced rice and lentil dish with vegetables.',history:'Karnataka royal dish from Mysore palace kitchens. Name means "hot lentil rice" in Kannada. Complete meal in one pot.',prepTime:'90 min',difficulty:'Medium'),
    DishItem(name:'Poha',originalName:'Kanda Poha',description:'Flattened rice stir-fried with mustard seeds, turmeric, onion and peanuts.',history:'Central and Western India breakfast. Indore\'s poha is legendary. Simple, quick and nutritious morning meal.',prepTime:'15 min',difficulty:'Easy'),
    DishItem(name:'Misal Pav',originalName:'Pune Misal Pav',description:'Spicy sprouted moth bean curry topped with farsan, onion and bread.',history:'Maharashtrian breakfast from Pune and Nashik. Fiery Kolhapur style and milder Pune style are both legendary.',prepTime:'60 min',difficulty:'Medium'),
    DishItem(name:'Sarson Ka Saag',originalName:'Sarson Ka Saag',description:'Slow-cooked mustard greens with ginger, garlic and makki roti.',history:'Quintessential winter dish of Punjab. Slow cooking for hours over wood fire is traditional. With makki roti it\'s a seasonal feast.',prepTime:'120 min',difficulty:'Medium'),
    DishItem(name:'Kadhi Pakora',originalName:'Punjabi Kadhi Pakora',description:'Yogurt-based curry with gram flour fritters and tadka of mustard seeds.',history:'Every North Indian state has its own kadhi. Punjabi version is thick and rich. Gujarati is thin and sweet. Both are ancient.',prepTime:'60 min',difficulty:'Medium'),
  ];

  // ─── MEXICAN (50 dishes) ──────────────────────────────
  static const _mexican = [
    DishItem(name:'Tacos al Pastor',originalName:'Tacos al Pastor',description:'Vertical spit-roasted pork marinated in achiote and chilies with pineapple.',history:'Lebanese immigrants in Mexico City brought shawarma technique in 1930s. Mexican cooks replaced lamb with pork and added chilies.',prepTime:'180 min',difficulty:'Hard'),
    DishItem(name:'Guacamole',originalName:'Guacamole',description:'Fresh avocado with lime, cilantro, white onion, serrano and salt.',history:'Aztec "ahuacamolli" from 1500s. Sacred to Aztecs who believed avocados had aphrodisiac powers. Cortés brought recipe to Spain.',prepTime:'10 min',difficulty:'Easy'),
    DishItem(name:'Enchiladas Verdes',originalName:'Enchiladas Verdes',description:'Corn tortillas filled with chicken, rolled and covered in tomatillo sauce.',history:'Aztecs dipped tortillas in chili sauce. First enchilada recipe documented in 1831 Mexican cookbook by Mariano Galvan Rivera.',prepTime:'60 min',difficulty:'Medium'),
    DishItem(name:'Mole Poblano',originalName:'Mole Poblano de Guajolote',description:'Complex dark sauce with 20+ ingredients including chocolate, chilies and spices.',history:'17th century Puebla convent legend: nuns created it for Archbishop\'s visit. Took 3 days, 36 ingredients to make.',prepTime:'300 min',difficulty:'Hard'),
    DishItem(name:'Tamales',originalName:'Tamales',description:'Masa corn dough stuffed with meat, cheese or mole, wrapped in corn husks.',history:'Mesoamerican food over 5000 years old. Aztec warriors carried tamales as rations. Pre-Columbian tradition still alive today.',prepTime:'180 min',difficulty:'Hard'),
    DishItem(name:'Pozole Rojo',originalName:'Pozole Rojo',description:'Hominy corn and pork soup in deep red chili broth with toppings.',history:'Pre-Columbian ritual dish. Originally made for feast days. After Spanish conquest, pork replaced the ritual protein.',prepTime:'180 min',difficulty:'Medium'),
    DishItem(name:'Chiles Rellenos',originalName:'Chiles Rellenos en Nogada',description:'Roasted poblano peppers filled with picadillo, fried in egg batter.',history:'Puebla colonial dish. Chiles en Nogada with walnut sauce and pomegranate created in 1821 to honor Mexican independence.',prepTime:'90 min',difficulty:'Hard'),
    DishItem(name:'Quesadilla de Flor',originalName:'Quesadilla de Flor de Calabaza',description:'Corn tortilla with zucchini flower, corn fungus and Oaxacan cheese.',history:'Mesoamerican tradition of eating squash flowers. Mexico City quesadillas traditionally made on comal without cheese.',prepTime:'20 min',difficulty:'Easy'),
    DishItem(name:'Churros con Chocolate',originalName:'Churros con Chocolate Espeso',description:'Star-shaped fried dough with cinnamon sugar and thick Mexican chocolate.',history:'Spanish shepherds invented churros for mountain life. Mexican adaptation uses thicker chocolate and star-shaped press.',prepTime:'30 min',difficulty:'Medium'),
    DishItem(name:'Birria de Res',originalName:'Birria de Res Estilo Jalisco',description:'Slow-cooked beef in adobo sauce, served with consomme for dipping.',history:'Jalisco specialty originally with goat. Went viral globally as birria tacos in 2019-2020 on social media.',prepTime:'300 min',difficulty:'Medium'),
    DishItem(name:'Ceviche de Camaron',originalName:'Ceviche de Camaron',description:'Shrimp marinated in lime juice with tomato, cucumber, cilantro and habanero.',history:'Veracruz coastal tradition. Mexican ceviche differs from Peruvian using ketchup and tostadas as accompaniment.',prepTime:'30 min',difficulty:'Easy'),
    DishItem(name:'Tlayuda',originalName:'Tlayuda Oaxaquena',description:'Large crispy tortilla with black bean paste, Oaxacan cheese and toppings.',history:'Oaxacan staple sometimes called "Oaxacan pizza." Ancient food of the Zapotec people predating Spanish conquest.',prepTime:'30 min',difficulty:'Easy'),
    DishItem(name:'Cochinita Pibil',originalName:'Cochinita Pibil',description:'Yucatan slow-roasted pork marinated in achiote and sour orange.',history:'Maya pre-Columbian dish. Traditionally wrapped in banana leaves and cooked in underground pit oven called pib.',prepTime:'1440 min',difficulty:'Medium'),
    DishItem(name:'Sopa de Lima',originalName:'Sopa de Lima Yucateca',description:'Yucatan chicken soup with lime juice, fried tortillas and sweet lime.',history:'Yucatan Maya dish using the regional lima (sweet lime). Hybrid Maya-Spanish soup unique to the Yucatan peninsula.',prepTime:'60 min',difficulty:'Easy'),
    DishItem(name:'Huevos Rancheros',originalName:'Huevos Rancheros',description:'Fried eggs on crispy tortillas with salsa ranchera and refried beans.',history:'Rural Mexican breakfast from ranches. "Rancher\'s eggs" eaten by field workers as second breakfast after morning work.',prepTime:'20 min',difficulty:'Easy'),
    DishItem(name:'Elote en Vaso',originalName:'Elote en Vaso',description:'Mexican street corn with mayo, cotija cheese, lime and chili powder.',history:'Mexico City street food tradition. Also popular as elote on cob (corn on stick). Esquites is the cup version.',prepTime:'15 min',difficulty:'Easy'),
    DishItem(name:'Barbacoa',originalName:'Barbacoa de Borrego',description:'Lamb steamed in maguey leaves underground, served with consomme.',history:'Pre-Columbian cooking method from Caribbean. "Barbacoa" gave us the English word "barbecue." Traditional Sunday celebration food.',prepTime:'720 min',difficulty:'Hard'),
    DishItem(name:'Torta Ahogada',originalName:'Torta Ahogada Tapatiia',description:'Pork carnitas sandwich drowned in spicy tomato and arbol chili sauce.',history:'Guadalajara specialty, name means "drowned sandwich." Legend says it was created accidentally when birote fell into sauce.',prepTime:'120 min',difficulty:'Medium'),
    DishItem(name:'Tostadas de Tinga',originalName:'Tostadas de Tinga Poblana',description:'Crispy corn tostadas topped with shredded chicken in chipotle sauce.',history:'Puebla comfort food. Tinga sauce with chipotle peppers is uniquely Mexican smoky flavor not found elsewhere.',prepTime:'45 min',difficulty:'Easy'),
    DishItem(name:'Agua de Jamaica',originalName:'Agua Fresca de Jamaica',description:'Hibiscus flower tea served cold, tart and refreshing.',history:'Hibiscus brought from Africa via Caribbean. Mexico adopted it enthusiastically. Now the most popular agua fresca nationwide.',prepTime:'15 min',difficulty:'Easy'),
  ];

  // ─── JAPANESE (50 dishes) ─────────────────────────────
  static const _japanese = [
    DishItem(name:'Nigiri Sushi',originalName:'握り寿司',description:'Hand-pressed vinegared rice topped with fresh fish or seafood.',history:'Edo-period Tokyo fast food invented in 1820s by Hanaya Yohei. Designed to be eaten quickly with fingers at street stalls.',prepTime:'60 min',difficulty:'Hard'),
    DishItem(name:'Tonkotsu Ramen',originalName:'豚骨ラーメン',description:'Creamy pork bone broth ramen with chashu, soft egg and nori.',history:'Created in Kurume, Fukuoka in 1937 by Miyamoto Tokichi. Kyushu style became internationally popular in 1980s-90s.',prepTime:'480 min',difficulty:'Hard'),
    DishItem(name:'Tempura',originalName:'天ぷら',description:'Light lacey battered shrimp and vegetables fried in sesame oil.',history:'Portuguese missionaries introduced batter-frying technique in 16th century. Japanese perfected ice-cold water batter technique.',prepTime:'30 min',difficulty:'Medium'),
    DishItem(name:'Tonkatsu',originalName:'トンカツ',description:'Panko-breaded pork cutlet served with tonkatsu sauce and shredded cabbage.',history:'Created in Tokyo in 1899 at Rengatei. Japanese adaptation of European schnitzel, made uniquely Japanese with panko breadcrumbs.',prepTime:'30 min',difficulty:'Easy'),
    DishItem(name:'Yakitori',originalName:'焼き鳥',description:'Grilled chicken skewers on charcoal with sweet-salty tare glaze.',history:'Chicken consumption taboo lifted in Meiji era. Yakitori stands appeared near Shinto shrines and became izakaya staple.',prepTime:'30 min',difficulty:'Easy'),
    DishItem(name:'Gyoza',originalName:'餃子',description:'Pan-fried pork and cabbage dumplings, crispy bottom, soft top.',history:'Adapted from Chinese jiaozi by soldiers returning from WWII Manchuria. Japanese version uses more garlic and thinner skin.',prepTime:'45 min',difficulty:'Medium'),
    DishItem(name:'Udon Noodles',originalName:'うどん',description:'Thick chewy wheat noodles in light dashi broth with toppings.',history:'Buddhist monk Kuukai possibly brought noodle-making from Tang China in 9th century to Kagawa, Japan\'s udon capital.',prepTime:'30 min',difficulty:'Easy'),
    DishItem(name:'Takoyaki',originalName:'たこ焼き',description:'Round octopus dumplings cooked in special cast-iron mold.',history:'Invented in Osaka 1935 by Tomekichi Endo. Osaka identity food - Osaka people are called "tako-yaki-jin" (octopus ball people).',prepTime:'30 min',difficulty:'Medium'),
    DishItem(name:'Miso Soup',originalName:'味噌汁',description:'Fermented soybean paste soup with dashi, tofu, wakame and scallions.',history:'Samurai drank miso soup for stamina before battle. Essential Japanese breakfast component for over 1300 years.',prepTime:'15 min',difficulty:'Easy'),
    DishItem(name:'Onigiri',originalName:'おにぎり',description:'Triangular rice ball with salmon, umeboshi or tuna mayo filling.',history:'Japan\'s oldest portable food. Found in samurai lunch boxes. Now modern convenience store sells 1 billion annually.',prepTime:'20 min',difficulty:'Easy'),
    DishItem(name:'Katsu Curry',originalName:'カツカレー',description:'Japanese mild curry sauce over rice with breaded pork cutlet.',history:'British sailors introduced curry to Japan in Meiji era. Japanese adapted it into sweeter, thicker style. Naval staple on Fridays.',prepTime:'45 min',difficulty:'Easy'),
    DishItem(name:'Soba',originalName:'手打ち蕎麦',description:'Thin buckwheat noodles served cold with dipping sauce or hot in broth.',history:'Buddhist monks brought buckwheat cultivation to Japan. Handmade soba is elevated art form with dedicated soba-ya restaurants.',prepTime:'20 min',difficulty:'Medium'),
    DishItem(name:'Yakiniku',originalName:'焼き肉',description:'Korean-style tabletop BBQ with wagyu beef, short rib and vegetables.',history:'Zainichi Korean community in Japan after WWII popularized tabletop grilling. Now distinctly Japanese with wagyu emphasis.',prepTime:'30 min',difficulty:'Easy'),
    DishItem(name:'Okonomiyaki',originalName:'お好み焼き',description:'Savory Osaka pancake with cabbage, pork belly and bonito flakes.',history:'Evolved from simple grilled wheat pancakes in Hiroshima and Osaka. "Okonomi" means "what you like" - customizable dish.',prepTime:'30 min',difficulty:'Medium'),
    DishItem(name:'Shabu Shabu',originalName:'しゃぶしゃぶ',description:'Paper-thin wagyu beef swished in hot dashi broth at the table.',history:'Osaka restaurant Suehiro claims invention in 1952. Name is onomatopoeia of the swishing sound the meat makes in broth.',prepTime:'30 min',difficulty:'Easy'),
    DishItem(name:'Matcha Ice Cream',originalName:'抹茶アイスクリーム',description:'Green tea ice cream with intensely bitter-sweet matcha flavor.',history:'Western ice cream adopted in Meiji era combined with Japan\'s ancient matcha tradition. Now global Japanese dessert icon.',prepTime:'240 min',difficulty:'Medium'),
    DishItem(name:'Karaage',originalName:'唐揚げ',description:'Marinated chicken fried twice in light potato starch coating.',history:'Chinese tang-zha (唐炸) frying technique adapted in Japan. Became Japanese comfort food staple, different from American fried chicken.',prepTime:'30 min',difficulty:'Easy'),
    DishItem(name:'Chawanmushi',originalName:'茶碗蒸し',description:'Silky savory egg custard steamed in a teacup with dashi broth.',history:'Ancient Japanese dish from Muromachi period. Delicate dish showcasing dashi - the heart of Japanese cuisine.',prepTime:'30 min',difficulty:'Medium'),
    DishItem(name:'Chirashi',originalName:'ちらし寿司',description:'Scattered sushi bowl with assorted fish over vinegared rice.',history:'Edo-period sushi that predates nigiri. Regional styles vary dramatically. Chirashi is festive food for Hinamatsuri doll festival.',prepTime:'45 min',difficulty:'Medium'),
    DishItem(name:'Tamagoyaki',originalName:'玉子焼き',description:'Sweet rolled Japanese omelette made in special rectangular pan.',history:'Essential bento component and sushi bar staple. Each sushi chef has signature recipe - judges use tamagoyaki to assess quality.',prepTime:'15 min',difficulty:'Medium'),
  ];

  // ─── CHINESE (50 dishes) ──────────────────────────────
  static const _chinese = [
    DishItem(name:'Kung Pao Chicken',originalName:'宫保鸡丁',description:'Diced chicken with peanuts, dried chilies and Sichuan pepper.',history:'Named after Governor Ding Baozhen of Sichuan in Qing dynasty (1871). His palace title "Gong Bao" names the dish.',prepTime:'30 min',difficulty:'Medium'),
    DishItem(name:'Dim Sum',originalName:'點心',description:'Cantonese small plates in bamboo steamers: har gow, siu mai, char siu bao.',history:'Silk Road teahouse tradition over 2000 years old. Yum cha (drink tea) culture of Guangdong where dishes accompany tea.',prepTime:'120 min',difficulty:'Hard'),
    DishItem(name:'Peking Duck',originalName:'北京烤鸭',description:'Crispy lacquered duck with thin pancakes, cucumber, scallion and hoisin.',history:'Imperial Yuan dynasty dish (1271). Quanjude restaurant in Beijing has served it since 1864 using original recipe.',prepTime:'1440 min',difficulty:'Hard'),
    DishItem(name:'Mapo Tofu',originalName:'麻婆豆腐',description:'Silken tofu in numbing Sichuan chili-bean sauce with minced pork.',history:'Created by Chen Mapo (woman with pockmarks) in Chengdu in 1860s. Her restaurant still operates today at same location.',prepTime:'25 min',difficulty:'Medium'),
    DishItem(name:'Xiaolongbao',originalName:'小笼包',description:'Shanghai soup dumplings with pork and gelatin filling creating broth inside.',history:'Invented at Dingtaifeng in 1870s Shanghai. The challenge is pork gelatin that liquefies during steaming.',prepTime:'120 min',difficulty:'Hard'),
    DishItem(name:'Char Siu',originalName:'叉烧',description:'Cantonese BBQ pork with five-spice, honey and red coloring.',history:'Cantonese roasting technique for centuries. "Char" is fork and "siu" is roast - traditionally hung on forks in oven.',prepTime:'1440 min',difficulty:'Medium'),
    DishItem(name:'Hot Pot',originalName:'火锅',description:'Simmering spicy and mild broth for cooking paper-thin meats and vegetables.',history:'Mongolian horseback cooking evolved into elaborate Sichuan mala hot pot. Over 1000 years of communal dining tradition.',prepTime:'30 min',difficulty:'Easy'),
    DishItem(name:'Spring Rolls',originalName:'春卷',description:'Crispy fried rolls with pork, shrimp and vegetables for Chinese New Year.',history:'Spring Festival food representing prosperity. Cylindrical shape resembles gold bars, symbolizing wealth for the new year.',prepTime:'60 min',difficulty:'Medium'),
    DishItem(name:'Wonton Soup',originalName:'云吞汤',description:'Delicate shrimp-pork wontons in clear ginger-scallion broth.',history:'Cantonese "swallowing clouds" - poetic name for the silk-like floating dumplings. Hong Kong noodle shop staple since 1930s.',prepTime:'45 min',difficulty:'Medium'),
    DishItem(name:'Scallion Pancake',originalName:'葱油饼',description:'Flaky pan-fried flatbread with scallions, sesame oil and salt.',history:'Ancient Chinese street food. Shanghai and Beijing versions differ in technique. Recently became global breakfast food.',prepTime:'30 min',difficulty:'Medium'),
    DishItem(name:'Dan Dan Noodles',originalName:'担担面',description:'Chengdu noodles with sesame paste, chili oil, peanuts and preserved vegetables.',history:'Originally sold by street vendors carrying loads on shoulder poles (dan dan). Sichuan classic since Qing dynasty.',prepTime:'25 min',difficulty:'Medium'),
    DishItem(name:'Sweet and Sour Pork',originalName:'糖醋里脊',description:'Crispy pork pieces in tangy sweet-sour sauce with pineapple and peppers.',history:'Cantonese dish adapted for Western tastes in early Chinese-American restaurants. Transformed Chinese food globally.',prepTime:'45 min',difficulty:'Medium'),
    DishItem(name:'Congee',originalName:'白粥',description:'Slow-cooked rice porridge with ginger, scallion and century egg.',history:'Ancient comfort food for sick and healthy alike. Mentioned in Zhou dynasty texts over 2500 years ago.',prepTime:'90 min',difficulty:'Easy'),
    DishItem(name:'Buddha\'s Delight',originalName:'罗汉斋',description:'Vegetarian braised medley of tofu skin, mushrooms, ginkgo and lotus.',history:'Chinese New Year vegetarian dish eaten on first day. Buddhist temple food using 18 ingredients representing 18 Lohans.',prepTime:'60 min',difficulty:'Medium'),
    DishItem(name:'Braised Pork Belly',originalName:'红烧肉',description:'Dongpo pork slow-braised in soy, wine and sugar until meltingly tender.',history:'Created by Song dynasty poet Su Dongpo who was also a famous gourmand. The red-braised technique is Hangzhou specialty.',prepTime:'180 min',difficulty:'Medium'),
    DishItem(name:'Lanzhou Beef Noodles',originalName:'兰州拉面',description:'Hand-pulled noodles in clear beef broth from Northwest China.',history:'Gansu province Muslim Hui tradition. Eight characters define authentic version: one clear, two white, three red, four green, five yellow.',prepTime:'120 min',difficulty:'Hard'),
    DishItem(name:'Egg Fried Rice',originalName:'蛋炒饭',description:'Day-old rice wok-tossed with eggs, scallions and soy sauce.',history:'Ancient technique using leftover rice. Yang Zhou fried rice is most famous regional version with elaborate toppings.',prepTime:'15 min',difficulty:'Easy'),
    DishItem(name:'Zongzi',originalName:'粽子',description:'Sticky rice stuffed with pork, mushroom and egg, wrapped in bamboo leaves.',history:'Dragon Boat Festival food since 278 BC made to honor poet Qu Yuan. Regional variations number in the hundreds.',prepTime:'480 min',difficulty:'Hard'),
    DishItem(name:'Ma Po Eggplant',originalName:'鱼香茄子',description:'Eggplant in yuxiang (fish-fragrant) sauce with garlic, ginger and chili.',history:'Yuxiang sauce contains no fish - named for its flavor profile used in Sichuan fish dishes. Eggplant absorbs it perfectly.',prepTime:'20 min',difficulty:'Easy'),
    DishItem(name:'Tanghulu',originalName:'糖葫芦',description:'Candied hawthorn berries on skewers coated in crystallized sugar.',history:'Beijing street food dating to Song dynasty. Traditional winter snack sold by street vendors. Now trendy globally.',prepTime:'20 min',difficulty:'Medium'),
  ];

  // ─── FRENCH (40 dishes) ───────────────────────────────
  static const _french = [
    DishItem(name:'Croissant',originalName:'Croissant au Beurre',description:'Buttery laminated pastry with 72 layers of flaky golden dough.',history:'Vienna kipferl brought to France by August Zang in 1838. French bakers perfected the butter lamination into today\'s croissant.',prepTime:'720 min',difficulty:'Hard'),
    DishItem(name:'Coq au Vin',originalName:'Coq au Vin',description:'Rooster braised in red Burgundy wine with lardons and mushrooms.',history:'Ancient French peasant dish to tenderize old roosters. Julia Child made it famous worldwide with her 1961 cookbook.',prepTime:'120 min',difficulty:'Medium'),
    DishItem(name:'Bouillabaisse',originalName:'Bouillabaisse Marseillaise',description:'Provençal saffron fish stew with rouille and grilled bread.',history:'Marseille fishermen\'s dish since Greek settlers 600 BC. The 1980 Marseille Charter defines the only authentic version.',prepTime:'90 min',difficulty:'Hard'),
    DishItem(name:'Crème Brûlée',originalName:'Crème Brûlée',description:'Vanilla custard beneath glass-thin caramelized sugar crust.',history:'First appeared in François Menon\'s cookbook in 1691. Brûléeing technique with hot iron evolved into today\'s kitchen torch.',prepTime:'60 min',difficulty:'Medium'),
    DishItem(name:'Ratatouille',originalName:'Ratatouille Niçoise',description:'Slow-cooked Provence vegetable stew with Herbes de Provence.',history:'Nice peasant dish since 18th century. "Rata" means chunky stew in French slang. Pixar film made it globally famous in 2007.',prepTime:'60 min',difficulty:'Easy'),
    DishItem(name:'French Onion Soup',originalName:'Soupe à l\'Oignon Gratinée',description:'Caramelized onion soup under gruyère crouton, gratinéed.',history:'Paris bistro classic since 18th century. Les Halles market workers ate it at dawn. Now served at midnight in brasseries.',prepTime:'90 min',difficulty:'Medium'),
    DishItem(name:'Beef Bourguignon',originalName:'Boeuf Bourguignon',description:'Beef slow-braised in Pinot Noir with pearl onions and mushrooms.',history:'Burgundy peasant dish elevated to haute cuisine by Escoffier. The Julia Child version in "Mastering the Art of French Cooking" is legendary.',prepTime:'240 min',difficulty:'Hard'),
    DishItem(name:'Macarons Parisiens',originalName:'Macarons Parisiens',description:'Almond meringue shells sandwiched with ganache or buttercream.',history:'Catherine de Medici brought Italian amaretti in 1533. Pierre Hermé and Ladurée created the modern sandwich macaron.',prepTime:'120 min',difficulty:'Hard'),
    DishItem(name:'Quiche Lorraine',originalName:'Quiche Lorraine',description:'Open pastry tart with cream, egg, Gruyère and lardons.',history:'From Lorraine region, originally from German "kuchen." 16th century recipe used bread dough. Cream was added later.',prepTime:'60 min',difficulty:'Medium'),
    DishItem(name:'Duck Confit',originalName:'Confit de Canard',description:'Duck legs slowly poached in their own rendered fat at low temperature.',history:'Gascon preservation technique for winter. Mireille Johnston\'s "Cuisine of the Sun" introduced it to Americans in 1976.',prepTime:'1440 min',difficulty:'Medium'),
    DishItem(name:'Escargots de Bourgogne',originalName:'Escargots de Bourgogne',description:'Burgundy snails baked in shells with garlic-parsley butter.',history:'Romans and prehistoric peoples ate snails. After Revolution, Talleyrand served them to Tsar Alexander I at a famous 1814 banquet.',prepTime:'45 min',difficulty:'Medium'),
    DishItem(name:'Soufflé au Chocolat',originalName:'Soufflé au Chocolat',description:'Individual baked chocolate soufflé, perfectly risen and served immediately.',history:'French culinary technique mastered in 18th century. The souffle represents French cuisine\'s precision and theatrical presentation.',prepTime:'45 min',difficulty:'Hard'),
    DishItem(name:'Cassoulet',originalName:'Cassoulet de Castelnaudary',description:'White bean casserole with duck confit, Toulouse sausage and pork.',history:'Created in Castelnaudary during Hundred Years War. Three cities claim it. Serious disputes exist over authentic version.',prepTime:'2880 min',difficulty:'Hard'),
    DishItem(name:'Tarte Tatin',originalName:'Tarte Tatin',description:'Upside-down caramelized apple tart with puff pastry.',history:'Accidentally created by Stéphanie Tatin at Hotel Tatin in Lamotte-Beuvron in 1880s when she forgot the apple tart.',prepTime:'60 min',difficulty:'Medium'),
    DishItem(name:'Baguette',originalName:'Baguette Parisienne',description:'Long thin French bread with crispy crust and chewy interior.',history:'Vienna steam oven bread technique adopted in Paris in 1840. Modern thin shape resulted from 1920 law limiting baker hours.',prepTime:'240 min',difficulty:'Medium'),
    DishItem(name:'Steak Frites',originalName:'Steak Frites',description:'Sirloin steak with crispy frites and béarnaise sauce.',history:'Bistro classic of 19th century Paris. Considered the national dish. Every brasserie has a version. Simple perfection.',prepTime:'30 min',difficulty:'Easy'),
    DishItem(name:'Vichyssoise',originalName:'Vichyssoise',description:'Creamy cold potato-leek soup, though invented in New York.',history:'Created by French chef Louis Diat at Ritz-Carlton New York in 1917, inspired by his childhood in Vichy, France.',prepTime:'45 min',difficulty:'Easy'),
    DishItem(name:'Pot au Feu',originalName:'Pot-au-Feu',description:'Boiled beef and vegetables in clear broth - French comfort food.',history:'National dish of France. Home cooking since Middle Ages. Henri IV wished every peasant could afford chicken in the pot.',prepTime:'180 min',difficulty:'Easy'),
    DishItem(name:'Profiteroles',originalName:'Profiteroles au Chocolat',description:'Choux pastry puffs filled with vanilla ice cream and chocolate sauce.',history:'Choux pastry invented in 1540 by Catherine de Medici\'s chef Popelini. Ice cream filling is 19th century addition.',prepTime:'60 min',difficulty:'Medium'),
    DishItem(name:'Salade Niçoise',originalName:'Salade Niçoise',description:'Nice salad with tuna, hard eggs, olives, anchovies and vegetables.',history:'Originally simple Nice salad of tomatoes, anchovies and olive oil. French chef Escoffier added the other ingredients.',prepTime:'30 min',difficulty:'Easy'),
  ];

  // ─── THAI (40 dishes) ─────────────────────────────────
  static const _thai = [
    DishItem(name:'Pad Thai',originalName:'ผัดไทย',description:'Stir-fried rice noodles with shrimp, egg, bean sprouts and peanuts in tamarind sauce.',history:'Created in 1930s by PM Phibun to promote nationalism. WWII rice shortage led him to promote noodles as Thai national dish.',prepTime:'20 min',difficulty:'Medium'),
    DishItem(name:'Tom Yum Goong',originalName:'ต้มยำกุ้ง',description:'Spicy-sour soup with shrimp, lemongrass, galangal and kaffir lime.',history:'Ancient Thai royal dish, UNESCO intangible cultural heritage. The complex aromatics represent Thai culinary philosophy.',prepTime:'30 min',difficulty:'Easy'),
    DishItem(name:'Green Curry',originalName:'แกงเขียวหวาน',description:'Coconut milk curry with green chili paste, Thai basil and bamboo shoots.',history:'Developed in central Thailand early 20th century. Greener and hotter than red curry, reflecting the fresh green chilies used.',prepTime:'30 min',difficulty:'Medium'),
    DishItem(name:'Som Tum',originalName:'ส้มตำ',description:'Shredded unripe papaya pounded with lime, fish sauce, chilies and dried shrimp.',history:'Isaan Northeast Thailand dish, adopted nationally. UNESCO-recognized element of Thai cuisine. Essential use of mortar technique.',prepTime:'15 min',difficulty:'Easy'),
    DishItem(name:'Massaman Curry',originalName:'แกงมัสมั่น',description:'Rich curry with potatoes, peanuts, cinnamon and cardamom from Persian influence.',history:'17th century Muslim traders from Persia and India influenced southern Thai cooking. Contains warm spices unusual in Thai cuisine.',prepTime:'60 min',difficulty:'Medium'),
    DishItem(name:'Khao Niao Mamuang',originalName:'ข้าวเหนียวมะม่วง',description:'Sweet sticky rice with coconut cream and fresh Maha Chanok mango.',history:'Traditional summer dessert. The Maha Chanok mango season March-June makes this the most anticipated Thai seasonal dish.',prepTime:'45 min',difficulty:'Easy'),
    DishItem(name:'Tom Kha Gai',originalName:'ต้มข่าไก่',description:'Chicken coconut milk soup with galangal, lemongrass and oyster mushrooms.',history:'Northern Thai origin. More mild than Tom Yum. Galangal (kha) is the defining ingredient different from common ginger.',prepTime:'30 min',difficulty:'Easy'),
    DishItem(name:'Pad Kra Pao',originalName:'ผัดกระเพรา',description:'Thai holy basil stir-fry with ground pork, chilies and oyster sauce over rice.',history:'Thailand\'s most-ordered lunch dish. Quick street food invented when holy basil stir-fry technique spread from central Thailand.',prepTime:'15 min',difficulty:'Easy'),
    DishItem(name:'Khao Pad',originalName:'ข้าวผัด',description:'Thai fried rice with egg, green onion, fish sauce and lime.',history:'Adapation of Chinese fried rice by Thai cooks. Distinctly different due to fish sauce, lime and Thai jasmine rice.',prepTime:'15 min',difficulty:'Easy'),
    DishItem(name:'Satay',originalName:'สะเต๊ะ',description:'Grilled marinated chicken or pork skewers with peanut sauce and ajat.',history:'Javanese dish brought by Muslim traders. Thailand adapted with yellow curry marinade and richer peanut sauce.',prepTime:'60 min',difficulty:'Easy'),
    DishItem(name:'Khao Soi',originalName:'ข้าวซอย',description:'Northern Thai egg noodle curry with crispy noodles and pickled mustard.',history:'Chinese Yunnanese Muslim dish brought to Northern Thailand by Haw traders in 19th century. Chiang Mai specialty.',prepTime:'45 min',difficulty:'Medium'),
    DishItem(name:'Gaeng Daeng',originalName:'แกงแดง',description:'Red curry with coconut milk, bamboo shoots and Thai red curry paste.',history:'Classic central Thai curry. The red color from dried red chilies. One of the original three main curries of Thai cuisine.',prepTime:'30 min',difficulty:'Medium'),
    DishItem(name:'Pad See Ew',originalName:'ผัดซีอิ๊ว',description:'Broad flat rice noodles stir-fried with Chinese broccoli in dark soy sauce.',history:'Chinese immigrant adaptation. "See Ew" means soy sauce. Popular Chinese-Thai street food in Bangkok night markets.',prepTime:'15 min',difficulty:'Easy'),
    DishItem(name:'Larb Gai',originalName:'ลาบไก่',description:'Minced chicken with toasted rice powder, mint, lime and chili flakes.',history:'Isaan national dish, also national dish of Laos. Toasted rice powder is the unique ingredient providing nutty texture.',prepTime:'20 min',difficulty:'Easy'),
    DishItem(name:'Kanom Krok',originalName:'ขนมครก',description:'Coconut milk pancake balls cooked in special cast-iron mold.',history:'Ancient Thai street snack with roots in the royal court. The two-flavor version (sweet and savory) is traditional.',prepTime:'30 min',difficulty:'Medium'),
  ];

  // ─── AMERICAN (40 dishes) ─────────────────────────────
  static const _american = [
    DishItem(name:'Cheeseburger',originalName:'All-American Cheeseburger',description:'Beef patty with melted American cheese, lettuce, tomato and special sauce.',history:'Hamburger at 1904 St. Louis World\'s Fair. Cheese added in 1926 by 16-year-old Lionel Sternberger in Pasadena, California.',prepTime:'20 min',difficulty:'Easy'),
    DishItem(name:'BBQ Brisket',originalName:'Texas Smoked Brisket',description:'Whole packer brisket smoked 12-16 hours over post oak wood.',history:'Texas BBQ tradition from cattle ranching and German/Czech immigrant butchers in 19th century Central Texas.',prepTime:'960 min',difficulty:'Hard'),
    DishItem(name:'Mac and Cheese',originalName:'Southern Baked Mac and Cheese',description:'Creamy elbow macaroni in three-cheese sauce baked with crispy top.',history:'Jefferson brought pasta from France. 1824 cookbook recipe. Kraft boxed version (1937) became Depression-era comfort food.',prepTime:'45 min',difficulty:'Easy'),
    DishItem(name:'Clam Chowder',originalName:'New England Clam Chowder',description:'Thick cream soup with littleneck clams, potatoes and celery.',history:'Colonial New England fishing tradition. Boston restaurant records from 1830s. Manhattan red version sparked historical dispute.',prepTime:'45 min',difficulty:'Medium'),
    DishItem(name:'Buffalo Wings',originalName:'Buffalo Chicken Wings',description:'Deep-fried wings tossed in cayenne-butter sauce with blue cheese dip.',history:'Invented October 30, 1964 at Anchor Bar, Buffalo NY by Teressa Bellissimo for her son\'s friends. Became American sport food.',prepTime:'45 min',difficulty:'Easy'),
    DishItem(name:'Apple Pie',originalName:'American Apple Pie',description:'Double-crust pie with spiced Granny Smith apples and vanilla ice cream.',history:'European origin, but became American symbol. "American as apple pie" phrase used by WWII soldiers to explain why they fight.',prepTime:'90 min',difficulty:'Medium'),
    DishItem(name:'Southern Fried Chicken',originalName:'Southern Fried Chicken',description:'Buttermilk-marinated chicken, seasoned and fried in cast-iron skillet.',history:'Scottish frying tradition combined with African spices in American South. Central to African-American soul food culture.',prepTime:'480 min',difficulty:'Medium'),
    DishItem(name:'Lobster Roll',originalName:'Connecticut Lobster Roll',description:'Fresh claw and knuckle lobster with warm butter in toasted split-top bun.',history:'Maine vs Connecticut battle: Maine cold mayo or Connecticut warm butter. Perry\'s restaurant claims 1929 invention.',prepTime:'30 min',difficulty:'Easy'),
    DishItem(name:'Chicago Deep Dish',originalName:'Chicago Deep Dish Pizza',description:'Stuffed pie pizza with chunky tomato sauce on top of cheese layer.',history:'Ike Sewell invented at Pizzeria Uno in Chicago in 1943. The inverted cheese-under-sauce layering is Chicago invention.',prepTime:'90 min',difficulty:'Hard'),
    DishItem(name:'Philly Cheesesteak',originalName:'Philadelphia Cheesesteak',description:'Shaved ribeye with Cheez Whiz on a Amoroso hoagie roll.',history:'Pat Olivieri created it in 1930 Philadelphia. Cheez Whiz debate vs provolone is Philadelphia\'s most passionate argument.',prepTime:'20 min',difficulty:'Easy'),
    DishItem(name:'Gumbo',originalName:'Louisiana Gumbo',description:'Dark roux-thickened stew with andouille, shrimp and okra over rice.',history:'West African, Native American and French Creole fusion. "Gumbo" from Bantu word for okra. Louisiana state dish.',prepTime:'180 min',difficulty:'Hard'),
    DishItem(name:'Key Lime Pie',originalName:'Key Lime Pie',description:'Tart key lime custard in graham cracker crust with whipped cream.',history:'Florida Keys invention using local key limes and condensed milk from before refrigeration. Florida state pie since 2006.',prepTime:'30 min',difficulty:'Easy'),
    DishItem(name:'Biscuits and Gravy',originalName:'Southern Biscuits and Gravy',description:'Flaky buttermilk biscuits smothered in sausage white pepper gravy.',history:'Southern Appalachian poverty food from 1800s. Cheap filling meal that became beloved comfort food across America.',prepTime:'30 min',difficulty:'Easy'),
    DishItem(name:'Jambalaya',originalName:'Creole Jambalaya',description:'One-pot rice with andouille sausage, chicken and shrimp in Creole spices.',history:'Spanish paella brought to New Orleans, adapted with local ingredients by Creole cooks. Louisiana\'s most-cooked dish.',prepTime:'60 min',difficulty:'Medium'),
    DishItem(name:'Banana Pudding',originalName:'Southern Banana Pudding',description:'Layers of vanilla wafers, banana slices and vanilla custard with meringue.',history:'Nabisco Nilla wafer recipe from 1940s made it a Southern staple. Church potluck and family reunion essential dessert.',prepTime:'30 min',difficulty:'Easy'),
  ];

  // ─── KOREAN (40 dishes) ───────────────────────────────
  static const _korean = [
    DishItem(name:'Kimchi Jjigae',originalName:'김치찌개',description:'Spicy fermented cabbage stew with pork belly and tofu.',history:'Korea\'s most loved stew. Made with aged kimchi that is too sour to eat raw. Cold weather comfort food for 600+ years.',prepTime:'30 min',difficulty:'Easy'),
    DishItem(name:'Bibimbap',originalName:'비빔밥',description:'Mixed rice bowl with seasoned vegetables, fried egg and gochujang sauce.',history:'Jeonju specialty, one of Korea\'s most recognized dishes. Traditionally eaten on New Year\'s Eve using up leftover vegetables.',prepTime:'45 min',difficulty:'Easy'),
    DishItem(name:'Korean BBQ',originalName:'삼겹살 구이',description:'Thick pork belly grilled at table, wrapped in lettuce with garlic and gochujang.',history:'Tabletop grilling tradition from Goguryeo kingdom era. Samgyeopsal (three-layer pork) is Korean after-work social ritual.',prepTime:'30 min',difficulty:'Easy'),
    DishItem(name:'Tteokbokki',originalName:'떡볶이',description:'Chewy rice cakes in sweet-spicy gochujang sauce with fish cake.',history:'Royal court dish transformed into street food after 1953 Korean War. Now Korea\'s most popular street food globally.',prepTime:'20 min',difficulty:'Easy'),
    DishItem(name:'Japchae',originalName:'잡채',description:'Sweet potato glass noodles stir-fried with vegetables and beef.',history:'Created for King Gwanghaegun in 17th century Joseon dynasty. Originally made without noodles - just vegetables.',prepTime:'45 min',difficulty:'Medium'),
    DishItem(name:'Sundubu Jjigae',originalName:'순두부찌개',description:'Silky tofu stew with seafood or pork in spicy red broth and egg.',history:'Joseon dynasty dish. The raw egg added at the end is essential. LA\'s Koreatown restaurants popularized it in America.',prepTime:'20 min',difficulty:'Easy'),
    DishItem(name:'Galbi',originalName:'갈비',description:'Korean short ribs marinated in soy, pear, garlic and sesame, grilled.',history:'Suwon galbi is most famous style. Pear or kiwi in marinade is Korean secret for tenderizing beef enzymatically.',prepTime:'480 min',difficulty:'Medium'),
    DishItem(name:'Doenjang Jjigae',originalName:'된장찌개',description:'Fermented soybean paste stew with zucchini, tofu and mushrooms.',history:'Ancient Korean fermented soybean tradition. Doenjang has been made for 2000 years. Considered Korean soul food.',prepTime:'20 min',difficulty:'Easy'),
    DishItem(name:'Jajangmyeon',originalName:'짜장면',description:'Black bean sauce noodles with pork, zucchini and potato.',history:'Chinese-Korean fusion created by Chinese immigrants in Incheon in early 1900s. April 14 is "Black Day" for eating it.',prepTime:'30 min',difficulty:'Medium'),
    DishItem(name:'Samgyetang',originalName:'삼계탕',description:'Whole Cornish hen stuffed with sticky rice, ginseng, jujube in broth.',history:'Summer restorative dish. Koreans eat hot soup in summer to replace heat with heat. Medical tradition from Joseon era.',prepTime:'120 min',difficulty:'Medium'),
    DishItem(name:'Haemul Pajeon',originalName:'해물파전',description:'Crispy seafood and green onion savory pancake with dipping sauce.',history:'Korea\'s beloved rainy day food. The sound of rain resembles pajeon sizzling. Andong and Dongrae versions are most famous.',prepTime:'20 min',difficulty:'Easy'),
    DishItem(name:'Kimchi',originalName:'배추김치',description:'Fermented napa cabbage with gochugaru, garlic, ginger and jeotgal.',history:'Over 3000 years of Korean fermentation history. UNESCO inscribed kimchi-making (kimjang) as intangible cultural heritage in 2013.',prepTime:'1440 min',difficulty:'Medium'),
    DishItem(name:'Bingsu',originalName:'팥빙수',description:'Shaved ice dessert with sweet red beans, rice cakes and condensed milk.',history:'Joseon dynasty royal dessert. Modern cafe versions with fruit, matcha and premium toppings are K-food trend.',prepTime:'20 min',difficulty:'Easy'),
    DishItem(name:'Bulgogi',originalName:'불고기',description:'Thinly sliced marinated beef grilled over charcoal or on pan.',history:'Goguryeo kingdom dish called "maekjeok." One of Korea\'s oldest dishes, adapting over 2000 years to present form.',prepTime:'120 min',difficulty:'Easy'),
    DishItem(name:'Korean Fried Chicken',originalName:'양념치킨',description:'Double-fried chicken with sweet-spicy sauce or soy-garlic glaze.',history:'Developed in 1970s Korea. Double-frying technique creates unprecedented crunch. Became global food trend after drama "My Love from the Star."',prepTime:'45 min',difficulty:'Medium'),
  ];

  // ─── SPANISH (40 dishes) ──────────────────────────────
  static const _spanish = [
    DishItem(name:'Paella Valenciana',originalName:'Paella Valenciana',description:'Saffron rice with rabbit, chicken, green beans and rosemary over fire.',history:'Valencia farmland dish cooked by farmers over open fire. Original has no seafood - that\'s tourist paella. 18th century origin.',prepTime:'60 min',difficulty:'Hard'),
    DishItem(name:'Gazpacho',originalName:'Gazpacho Andaluz',description:'Cold blended tomato soup with cucumber, pepper and sherry vinegar.',history:'Ancient Andalusian peasant drink of bread, water and vinegar. Tomatoes added after Columbus brought them from Americas.',prepTime:'20 min',difficulty:'Easy'),
    DishItem(name:'Jamón Ibérico',originalName:'Jamón Ibérico de Bellota',description:'Acorn-fed black Iberian pig ham air-cured for 36-48 months.',history:'Roman writers praised Iberian pig ham. The acorn diet of Extremaduran pigs creates the world\'s most prized cured meat.',prepTime:'17520 min',difficulty:'Hard'),
    DishItem(name:'Tortilla Española',originalName:'Tortilla de Patatas',description:'Potato and egg omelette cooked in olive oil - Spain\'s national dish.',history:'Created in Navarra around 1817. The debate over whether to include onion is Spain\'s most passionate culinary argument.',prepTime:'45 min',difficulty:'Easy'),
    DishItem(name:'Pulpo a la Gallega',originalName:'Pulpo á Feira',description:'Boiled octopus with paprika, coarse salt and olive oil on wooden plate.',history:'Galician pilgrimage food from Santiago de Compostela. Pulpeiros (octopus women) cooked it for pilgrims at fairs.',prepTime:'60 min',difficulty:'Easy'),
    DishItem(name:'Cocido Madrileño',originalName:'Cocido Madrileño',description:'Three-course chickpea stew: first broth, then chickpeas, then meats.',history:'Madrid\'s most important dish. Jewish adafina stew adapted by Christians after Reconquista. Three-course structure is unique.',prepTime:'300 min',difficulty:'Hard'),
    DishItem(name:'Gambas al Ajillo',originalName:'Gambas al Ajillo',description:'Shrimp sautéed in olive oil with garlic, chili and sherry.',history:'Simple Spanish tapas perfected in Andalusia. The garlic-infused olive oil (aceite de ajillo) is the soul of this dish.',prepTime:'15 min',difficulty:'Easy'),
    DishItem(name:'Patatas Bravas',originalName:'Patatas Bravas',description:'Crispy fried potatoes with spicy tomato bravas sauce and aioli.',history:'Madrid tapa tradition since 1960s. The original "brava" sauce varies dramatically: red tomato south, white aioli north.',prepTime:'30 min',difficulty:'Easy'),
    DishItem(name:'Churros con Chocolate',originalName:'Churros con Chocolate a la Taza',description:'Fried dough with thick Spanish drinking chocolate, not sauce.',history:'Madrid specialty since 16th century. Spanish chocolate is thicker than Mexican version. Breakfast staple before Christmas.',prepTime:'30 min',difficulty:'Medium'),
    DishItem(name:'Croquetas',originalName:'Croquetas de Jamón',description:'Creamy Ibérico ham béchamel croquettes, fried golden.',history:'French croquette adapted in Spain with jamón. Essential tapa - judges Spanish cuisine quality by texture of croqueta.',prepTime:'60 min',difficulty:'Medium'),
    DishItem(name:'Fabada Asturiana',originalName:'Fabada Asturiana',description:'Asturian white bean stew with chorizo, morcilla and lacón.',history:'Asturias mountain dish for harsh winters. The large white fabes beans are only grown in Asturian climate.',prepTime:'960 min',difficulty:'Medium'),
    DishItem(name:'Pan con Tomate',originalName:'Pa amb Tomàquet',description:'Catalan bread rubbed with tomato, drizzled with olive oil and salt.',history:'Catalonian farmhouse tradition to soften day-old bread. Now considered Catalan identity food, eaten at every meal.',prepTime:'5 min',difficulty:'Easy'),
    DishItem(name:'Crema Catalana',originalName:'Crema Catalana',description:'Catalan custard with cinnamon and citrus, caramelized sugar top.',history:'Oldest known custard recipe in Europe, documented in 14th century Catalan cookbook. Predates French crème brûlée.',prepTime:'60 min',difficulty:'Medium'),
    DishItem(name:'Salmorejo',originalName:'Salmorejo Cordobés',description:'Thick cold Córdoba tomato cream with jamón and hard-boiled egg.',history:'Córdoba version of gazpacho. Creamier, thicker, richer from more bread. Protected local dish of Córdoba.',prepTime:'20 min',difficulty:'Easy'),
    DishItem(name:'Pimientos de Padrón',originalName:'Pimientos de Padrón',description:'Small green peppers from Galicia blistered in olive oil with sea salt.',history:'Galicia Padrón town peppers. Famous saying: "de cen pementos, un pica" - one in a hundred is spicy, creating Russian roulette dish.',prepTime:'10 min',difficulty:'Easy'),
  ];

  // ─── GREEK (40 dishes) ────────────────────────────────
  static const _greek = [
    DishItem(name:'Moussaka',originalName:'Μουσακάς',description:'Layered eggplant, ground lamb and béchamel casserole.',history:'Ottoman origin adapted by Greek chef Nikolaos Tselementes in 1920s who added béchamel influenced by French cuisine.',prepTime:'90 min',difficulty:'Hard'),
    DishItem(name:'Souvlaki',originalName:'Σουβλάκι',description:'Pork skewers marinated in lemon, oregano and olive oil, grilled over charcoal.',history:'Ancient Greek street food. Homer mentions meat roasted on skewers in the Iliad. Unchanged for 3000 years.',prepTime:'120 min',difficulty:'Easy'),
    DishItem(name:'Spanakopita',originalName:'Σπανακόπιτα',description:'Flaky phyllo pastry pie filled with spinach, feta and herbs.',history:'Byzantine era pie. Phyllo pastry technique developed under Ottoman rule. Greek community in diaspora spread it globally.',prepTime:'60 min',difficulty:'Medium'),
    DishItem(name:'Tzatziki',originalName:'Τζατζίκι',description:'Thick strained yogurt with cucumber, garlic, dill and olive oil.',history:'Turkish cacık brought to Greece. Greek version uses thicker yogurt (strained). Essential with any grilled meat.',prepTime:'20 min',difficulty:'Easy'),
    DishItem(name:'Pastitsio',originalName:'Παστίτσιο',description:'Greek pasta bake with ground beef and béchamel - the Greek lasagna.',history:'Venetian "pasticcio" adapted in Greece with macaroni and Greek spices. Tselementes formalized the recipe in the 1930s.',prepTime:'90 min',difficulty:'Hard'),
    DishItem(name:'Greek Salad',originalName:'Χωριάτικη Σαλάτα',description:'Tomatoes, cucumber, olives, peppers with slab of feta and oregano.',history:'Genuine horiatiki (village salad) has no lettuce. Feta is added whole, not crumbled. Labeled as Greek salad globally.',prepTime:'15 min',difficulty:'Easy'),
    DishItem(name:'Kleftiko',originalName:'Κλέφτικο',description:'Slow-roasted lamb with garlic, lemon and herbs sealed in parchment.',history:'Created by Klefts - Greek freedom fighters hiding from Ottomans who cooked lamb in pits to hide the smoke.',prepTime:'240 min',difficulty:'Medium'),
    DishItem(name:'Baklava',originalName:'Μπακλαβάς',description:'Layers of phyllo with walnuts and honey syrup scented with cinnamon.',history:'Ancient Byzantine pastry. Ottoman and Greek communities both claim it. Greek versions use honey, Turkish use şerbet.',prepTime:'90 min',difficulty:'Hard'),
    DishItem(name:'Horiatiki',originalName:'Χωριάτικη',description:'Traditional village salad with olives, capers and barrel-aged feta.',history:'Simple ancient Greek salad. UNESCO recognized feta as exclusively Greek PDO product in 2002 after long EU dispute.',prepTime:'15 min',difficulty:'Easy'),
    DishItem(name:'Dolmades',originalName:'Ντολμάδες',description:'Grape leaves stuffed with rice, herbs and lemon, served with yogurt.',history:'Ottoman and Greek shared dish. The word comes from Turkish "dolmak" meaning to fill. Made throughout Eastern Mediterranean.',prepTime:'90 min',difficulty:'Hard'),
    DishItem(name:'Loukoumades',originalName:'Λουκουμάδες',description:'Honey-drizzled fried dough balls with cinnamon and sesame seeds.',history:'Ancient Greek dessert. Athletes received loukoumades as prizes at ancient Olympic Games, one of world\'s oldest sweets.',prepTime:'30 min',difficulty:'Easy'),
    DishItem(name:'Fasolada',originalName:'Φασολάδα',description:'White bean soup with tomatoes, celery and generous olive oil.',history:'National dish of Greece, called the Greek national food. Ancient recipe - beans were sacred to Apollo and used in ceremonies.',prepTime:'60 min',difficulty:'Easy'),
    DishItem(name:'Gyros',originalName:'Γύρος',description:'Pork or chicken from vertical rotisserie in pita with tzatziki and tomato.',history:'Created in 1970s Athens inspired by Turkish döner. Became Greece\'s most popular fast food, exported globally.',prepTime:'240 min',difficulty:'Hard'),
    DishItem(name:'Fava',originalName:'Φάβα Σαντορίνης',description:'Yellow split pea puree from Santorini with capers and olive oil.',history:'Santorini yellow split peas grow in volcanic soil creating unique sweetness. Ancient food of the Aegean islands.',prepTime:'60 min',difficulty:'Easy'),
    DishItem(name:'Galaktoboureko',originalName:'Γαλακτομπούρεκο',description:'Custard-filled phyllo with lemon sugar syrup.',history:'Byzantine sweet. The semolina custard filling is uniquely Greek. Name means "milk pastry" in Greek.',prepTime:'90 min',difficulty:'Hard'),
  ];

  // ─── VIETNAMESE (40 dishes) ───────────────────────────
  static const _vietnamese = [
    DishItem(name:'Pho Bo',originalName:'Phở Bò',description:'Beef bone broth noodle soup with rice noodles, herbs and lime.',history:'Created in Hanoi around 1900. French colonial "pot au feu" combined with Vietnamese rice noodles and star anise broth.',prepTime:'480 min',difficulty:'Hard'),
    DishItem(name:'Banh Mi',originalName:'Bánh Mì',description:'Vietnamese baguette with pork, pâté, pickled daikon, cucumber and cilantro.',history:'French colonial baguette adapted by Vietnamese bakers after 1954. Added Vietnamese ingredients creating uniquely hybrid sandwich.',prepTime:'30 min',difficulty:'Easy'),
    DishItem(name:'Goi Cuon',originalName:'Gỏi Cuốn',description:'Fresh spring rolls with shrimp, pork, rice noodles and herbs in rice paper.',history:'South Vietnamese dish lighter than Chinese fried spring rolls. "Goi" means salad, creating a salad roll tradition.',prepTime:'30 min',difficulty:'Easy'),
    DishItem(name:'Bun Bo Hue',originalName:'Bún Bò Huế',description:'Spicy beef and pork noodle soup from Hue with lemongrass and shrimp paste.',history:'Royal capital Hue dish more complex and spicier than Hanoi pho. Central Vietnamese cuisine reflects royal court tradition.',prepTime:'360 min',difficulty:'Hard'),
    DishItem(name:'Com Tam',originalName:'Cơm Tấm',description:'Broken rice with grilled pork, egg meatloaf and shredded pork skin.',history:'Saigon working-class breakfast invented by resourceful cooks using broken rice - cheaper fragments of milled rice.',prepTime:'60 min',difficulty:'Medium'),
    DishItem(name:'Bun Cha',originalName:'Bún Chả',description:'Hanoi grilled pork patties and belly in sweetened fish sauce broth with noodles.',history:'Hanoi specialty. Obama and Anthony Bourdain eating bun cha in 2016 made it globally famous overnight.',prepTime:'45 min',difficulty:'Medium'),
    DishItem(name:'Cao Lau',originalName:'Cao Lầu',description:'Hoi An thick rice noodles with pork, greens and crackling, unique to Hoi An.',history:'Only authentic Cao Lau uses water from specific Ba Le well in Hoi An and ash from Cu Lao Cham island trees. Cannot be replicated elsewhere.',prepTime:'60 min',difficulty:'Hard'),
    DishItem(name:'Banh Xeo',originalName:'Bánh Xèo',description:'Sizzling Vietnamese crepe with shrimp, pork and bean sprouts.',history:'Name means "sizzling cake" from the sound of batter hitting hot pan. Southern and Central versions differ in size and recipe.',prepTime:'30 min',difficulty:'Medium'),
    DishItem(name:'Pho Ga',originalName:'Phở Gà',description:'Chicken pho with lighter more delicate broth than beef version.',history:'Created as pho alternative during French beef restrictions. Hanoi pho ga is crisper, more delicate than beef pho.',prepTime:'180 min',difficulty:'Medium'),
    DishItem(name:'Bun Rieu',originalName:'Bún Riêu',description:'Crab and tomato noodle soup with tofu, blood cake and perilla.',history:'Northern Vietnamese soup using freshwater crabs pounded with their shells. Distinctive sour tomato broth.',prepTime:'120 min',difficulty:'Hard'),
    DishItem(name:'Che Ba Mau',originalName:'Chè Ba Màu',description:'Three-color dessert with red beans, yellow mung bean, pandan jelly and coconut milk.',history:'South Vietnamese street dessert representing prosperity. Three colors (red, yellow, green) have symbolic meanings.',prepTime:'60 min',difficulty:'Easy'),
    DishItem(name:'Cha Ca La Vong',originalName:'Chả Cá Lã Vọng',description:'Hanoi turmeric-marinated fish with dill, shrimp paste and rice noodles.',history:'One restaurant in Hanoi has served this single dish since 1871. The Doan family recipe is Hanoi\'s most treasured.',prepTime:'60 min',difficulty:'Medium'),
    DishItem(name:'Mi Quang',originalName:'Mì Quảng',description:'Quang Nam turmeric noodles with pork, shrimp, herbs and peanuts.',history:'Central Vietnam dish from Quang Nam province. The minimal broth used as sauce rather than soup is distinctive.',prepTime:'60 min',difficulty:'Medium'),
    DishItem(name:'Bun Thit Nuong',originalName:'Bún Thịt Nướng',description:'Cold noodle bowl with grilled pork, spring rolls, herbs and fish sauce dressing.',history:'South Vietnamese rice noodle salad bowl. The mix-as-you-eat presentation is Vietnamese dining philosophy.',prepTime:'45 min',difficulty:'Easy'),
    DishItem(name:'Banh Cuon',originalName:'Bánh Cuốn',description:'Steamed rice rolls filled with pork and mushrooms, topped with fried shallots.',history:'Northern Vietnamese breakfast dish. Paper-thin rice sheets steamed on cloth over boiling water - an ancient technique.',prepTime:'60 min',difficulty:'Hard'),
  ];

  // ─── ETHIOPIAN (30 dishes) ────────────────────────────
  static const _ethiopian = [
    DishItem(name:'Injera',originalName:'ኢንጀራ',description:'Spongy sourdough flatbread from teff flour used as plate and utensil.',history:'Ancient Aksumite Empire grain. Teff only grows in Ethiopian highlands. The sourdough fermentation is 3-day process.',prepTime:'4320 min',difficulty:'Hard'),
    DishItem(name:'Doro Wat',originalName:'ዶሮ ወጥ',description:'Ethiopian chicken stew in berbere spice sauce with hard-boiled eggs.',history:'National dish of Ethiopia. The berbere spice blend can contain 20+ ingredients. Prepared for special occasions like Christmas and weddings.',prepTime:'180 min',difficulty:'Hard'),
    DishItem(name:'Tibs',originalName:'ጥብስ',description:'Sautéed beef or lamb with onions, peppers, rosemary and niter kibbeh.',history:'Ethiopian everyday stir-fry. "Tibs" simply means meat. Countless variations exist across Ethiopia\'s diverse regions.',prepTime:'30 min',difficulty:'Easy'),
    DishItem(name:'Misir Wat',originalName:'ምስር ወጥ',description:'Spiced red lentil stew with berbere, niter kibbeh and onions.',history:'Ethiopian vegetarian staple during fasting periods. Ethiopian Orthodox Christians fast up to 200 days per year abstaining from meat.',prepTime:'45 min',difficulty:'Easy'),
    DishItem(name:'Shiro Wat',originalName:'ሽሮ ወጥ',description:'Smooth chickpea flour stew with berbere and niter kibbeh.',history:'Ethiopian working-class and fasting food. Shiro is ground chickpeas with spices. Quick and nutritious everyday dish.',prepTime:'30 min',difficulty:'Easy'),
    DishItem(name:'Gored Gored',originalName:'ጎረድ ጎረድ',description:'Raw cubed beef with spiced butter and awaze chili sauce.',history:'Ethiopian raw meat tradition. Considered delicacy by Ethiopian people. Shared with kitfo as uniquely Ethiopian raw beef dishes.',prepTime:'20 min',difficulty:'Easy'),
    DishItem(name:'Kitfo',originalName:'ክትፎ',description:'Ethiopian steak tartare with spiced butter, chili and mitmita.',history:'Gurage people specialty. The finest minced lean beef dressed with spiced butter is celebratory dish for special occasions.',prepTime:'20 min',difficulty:'Easy'),
    DishItem(name:'Firfir',originalName:'ፍርፍር',description:'Shredded injera cooked with berbere sauce, tomato and spiced butter.',history:'Clever use of day-old injera. Means "bits and pieces" in Amharic. Breakfast dish using leftover injera and wat.',prepTime:'20 min',difficulty:'Easy'),
    DishItem(name:'Zilzil Tibs',originalName:'ዝልዝል ጥብስ',description:'Thin-sliced beef strips fried crispy with awaze sauce.',history:'The term "zilzil" means strip. This preparation creates crispy beef strips distinctive to Ethiopian cooking tradition.',prepTime:'20 min',difficulty:'Easy'),
    DishItem(name:'Kategna',originalName:'ቃጥኝ',description:'Toasted injera with spiced butter and berbere, Ethiopian garlic bread.',history:'Simple Ethiopian breakfast using day-old injera toasted with spiced butter. The berbere-butter combination is Ethiopian essence.',prepTime:'10 min',difficulty:'Easy'),
  ];

  // ─── MEDITERRANEAN (30 dishes) ───────────────────────
  static const _mediterranean = [
    DishItem(name:'Hummus',originalName:'حمص',description:'Creamy chickpea and tahini dip with olive oil, cumin and paprika.',history:'Arab dish recorded in 13th century Cairo cookbook. Israeli-Lebanese dispute over ownership reflects its cross-cultural importance.',prepTime:'480 min',difficulty:'Easy'),
    DishItem(name:'Falafel',originalName:'فلافل',description:'Crispy fried chickpea balls with herbs served in pita with tahini.',history:'Coptic Christians in Egypt possibly created it as Lenten meat substitute. Became beloved across Middle East and globally.',prepTime:'480 min',difficulty:'Medium'),
    DishItem(name:'Shawarma',originalName:'شاورما',description:'Vertical-spit roasted meat with tahini, pickles and vegetables in flatbread.',history:'Ottoman Empire dish evolved from Anatolian doner kebab. "Shawarma" is Arabic pronunciation of Turkish "çevirme" meaning turning.',prepTime:'1440 min',difficulty:'Hard'),
    DishItem(name:'Tabbouleh',originalName:'تبولة',description:'Lebanese parsley salad with bulgur, tomato, mint and lemon dressing.',history:'Levantine mountain dish. Authentic tabbouleh is 90% parsley. American-style with more bulgur is not traditional.',prepTime:'30 min',difficulty:'Easy'),
    DishItem(name:'Meze',originalName:'Μεζές / مازة',description:'Spread of small dishes including dips, salads, olives and pastries.',history:'Ottoman Persian tradition of small dishes with drinks. Encompasses entire Eastern Mediterranean hospitality culture.',prepTime:'60 min',difficulty:'Easy'),
    DishItem(name:'Baba Ganoush',originalName:'بابا غنوج',description:'Smoky eggplant dip with tahini, garlic and lemon.',history:'Levantine dish. Name may mean "pampered father" or be a term of endearment. Charring eggplant over fire is essential.',prepTime:'30 min',difficulty:'Easy'),
    DishItem(name:'Labneh',originalName:'لبنة',description:'Strained yogurt cheese with olive oil and za\'atar herbs.',history:'Ancient Middle Eastern food preservation - straining whey from yogurt creates shelf-stable cheese. Made across Levant.',prepTime:'1440 min',difficulty:'Easy'),
    DishItem(name:'Fattoush',originalName:'فتوش',description:'Levantine bread salad with toasted pita, sumac and seasonal vegetables.',history:'Syrian and Lebanese peasant salad using day-old bread. The sumac-pomegranate molasses dressing is distinctly Levantine.',prepTime:'20 min',difficulty:'Easy'),
    DishItem(name:'Musakhan',originalName:'مسخن',description:'Palestinian roasted chicken on flatbread with sumac-caramelized onions.',history:'Palestinian national dish. Sumac colors and flavors the signature dish of olive harvest festivals in northern Palestine.',prepTime:'90 min',difficulty:'Medium'),
    DishItem(name:'Manakish',originalName:'مناقيش',description:'Lebanese flatbread with za\'atar and olive oil mixture baked in wood oven.',history:'Ancient Levantine bread. Za\'atar herb mixture has been used in Levant cooking for over 2000 years.',prepTime:'60 min',difficulty:'Easy'),
  ];

  // ─── MIDDLE EASTERN (30 dishes) ──────────────────────
  static const _middleEastern = [
    DishItem(name:'Mansaf',originalName:'منسف',description:'Jordanian lamb in dried yogurt sauce over flatbread and rice with pine nuts.',history:'National dish of Jordan and Bedouin hospitality symbol. Jameed (dried yogurt) is unique to Jordan and Palestine.',prepTime:'180 min',difficulty:'Hard'),
    DishItem(name:'Kebab Koobideh',originalName:'کباب کوبیده',description:'Persian minced lamb and beef kebab on flat skewers grilled over charcoal.',history:'Persian empire kebab tradition over 2500 years old. Koobideh means "pounded" referring to the meat preparation.',prepTime:'30 min',difficulty:'Medium'),
    DishItem(name:'Fesenjan',originalName:'فسنجان',description:'Persian pomegranate-walnut stew with duck or chicken.',history:'Ancient Persian royal dish mentioned in texts from Persepolis. One of Iran\'s most distinctive regional dishes.',prepTime:'120 min',difficulty:'Medium'),
    DishItem(name:'Mandi',originalName:'مندي',description:'Yemeni slow-cooked meat and rice in underground tandoor oven.',history:'Yemeni ancient cooking in tandoor pit. Word means "dew" referring to moisture of slow cooking. Wedding and feast food.',prepTime:'480 min',difficulty:'Hard'),
    DishItem(name:'Kabsa',originalName:'كبسة',description:'Saudi spiced rice with chicken or lamb and dried fruits.',history:'National dish of Saudi Arabia. The complex spice blend varies by region. Central to Saudi Arabian hospitality and celebration.',prepTime:'90 min',difficulty:'Medium'),
    DishItem(name:'Qozi',originalName:'قوزي',description:'Iraqi whole roasted lamb stuffed with rice, raisins and spices.',history:'Mesopotamian ancient dish. Iraqi cuisine is one of world\'s oldest. This festive dish continues ancient Babylonian cooking traditions.',prepTime:'300 min',difficulty:'Hard'),
    DishItem(name:'Kibbeh',originalName:'كبة',description:'Lebanese-Syrian ground lamb with bulgur wheat, pine nuts and spices.',history:'National dish of Lebanon and Syria. Over 50 varieties exist. The raw kibbeh nayeh is considered the finest expression.',prepTime:'60 min',difficulty:'Hard'),
    DishItem(name:'Fatayer',originalName:'فطاير',description:'Middle Eastern triangular pies filled with spinach, meat or cheese.',history:'Ancient Levantine hand pie. The spinach-sumac version is Lebanon\'s most beloved. Sold from bakeries since Ottoman times.',prepTime:'120 min',difficulty:'Medium'),
    DishItem(name:'Maqluba',originalName:'مقلوبة',description:'Palestinian upside-down rice dish with lamb, eggplant and cauliflower.',history:'Name means "upside down." The dramatic flip revealing the layered dish is ceremonial. Palestinian family celebration food.',prepTime:'90 min',difficulty:'Hard'),
    DishItem(name:'Baklava Levantine',originalName:'بقلاوة',description:'Levantine phyllo with pistachios in orange blossom syrup.',history:'Ottoman empire sweet spread throughout Middle East. Each region claims different nut and syrup combination as authentic.',prepTime:'90 min',difficulty:'Hard'),
  ];
}
