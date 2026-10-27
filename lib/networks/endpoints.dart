final class Endpoints {
  Endpoints._();

  // App Launch & Bootstrap
  static String bootstrap() => "/bootstrap";

  // Product Catalog & E-Commerce
  static String products() => "/products";
  static String productDetails(String slug) => "/products/$slug";
  static String relatedProducts(String slug) => "/products/$slug/related";
  static String categories() => "/category";
  static String categoryDetails(dynamic id) => "/category/$id";
  static String offers() => "/offers";

  // Cart, Checkout & Orders
  static String cartStore() => "/cartstore";
  static String customers() => "/customers";
  static String orderTracking(String orderId) => "/customers/$orderId";
  static String searchOrders() => "/customers/search/customerdata";

  // Telemedicine & Specialist Doctors
  static String specialistDepartments() => "/specialist-departments";
  static String specialistDoctors() => "/specialist-doctors";
  static String doctorDetails(int id) => "/specialist-doctors/$id";
  static String doctorSlots(int id) => "/specialist-doctors/$id/slots";
  static String bookConsultation() => "/consultation-bookings";
  static String trackConsultation(String id) =>
      "/consultation-bookings/track/$id";

  // Diagnostic Lab Tests & Home Collection
  static String labCategories() => "/lab-categories";
  static String labTests() => "/lab-tests";
  static String bookHomeLab() => "/home-lab-bookings";
  static String trackHomeLab(String id) => "/home-lab-bookings/track/$id";

  // Prescription Upload
  static String uploadPrescription() => "/prescriptions";

  // B2B Wholesale
  static String wholesaleProducts() => "/wholesale/products";
  static String wholesaleApplications() => "/wholesale-applications";
  static String trackWholesale(String query) => "/wholesale/track/$query";

  // User Auth & Coin Wallet
  static String userLogin() => "/userlogin";
  static String register() => "/users";
  static String userProfile() => "/user";
  static String userPoints(String phone) => "/users/$phone";
  static String bonusCoins() => "/bonuscoins";
  static String coinPackages() => "/coinpackages";
  static String coinTransactions() => "/cointransactions";

  // Delivery & Payments
  static String deliveryCharges() => "/deliverycharges";
  static String paymentMethods() => "/paymentmethod";
  static String codAdvances() => "/codadvances";

  // Leads & Contact
  static String leads() => "/leads";
  static String contacts() => "/contacts";
}
