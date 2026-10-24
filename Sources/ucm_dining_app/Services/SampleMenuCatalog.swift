import Foundation

/// Built-in UC Merced Pavilion & YWDC fallback catalog so the app works immediately offline or in SwiftUI Previews.
public enum SampleMenuCatalog {
    public static let pavilionDays: [DayMenuGroup] = [
        DayMenuGroup(id: "61bd808b5f2f930010bb6a7a", name: "SUNDAY", order: 0),
        DayMenuGroup(id: "61bd80908b34640010e194b3", name: "MONDAY", order: 1),
        DayMenuGroup(id: "61bd80ab5f2f930010bb6a7d", name: "TUESDAY", order: 2),
        DayMenuGroup(id: "61bd80b08b34640010e194b4", name: "WEDNESDAY", order: 3),
        DayMenuGroup(id: "61bd80b55f2f930010bb6a7e", name: "THURSDAY", order: 4),
        DayMenuGroup(id: "61bd80ba5f2f930010bb6a7f", name: "FRIDAY", order: 5),
        DayMenuGroup(id: "61bd80bf8b34640010e194b6", name: "SATURDAY", order: 6),
    ]

    public static let pavilionCategories: [MealCategory] = [
        MealCategory(
            id: "61bd80d68b34640010e194b8",
            name: "Breakfast",
            order: 0,
            explanationText: "Breakfast service runs from 7AM to 10:00AM Monday – Friday and 9AM to 10:30AM Saturday & Sunday."
        ),
        MealCategory(
            id: "61bd80d05f2f930010bb6a81",
            name: "Lunch",
            order: 1,
            explanationText: "Lunch Service runs from 11AM – 3PM Sunday – Saturday, seven days a week."
        ),
        MealCategory(
            id: "61bd80cc5f2f930010bb6a80",
            name: "Dinner",
            order: 2,
            explanationText: "Dinner service runs from 4PM to 9PM, seven days a week."
        ),
        MealCategory(
            id: "62d9c7c26c04ea00104859c7",
            name: "Bakery",
            order: 5,
            explanationText: "Freshly baked breads, pastries, and desserts prepared daily by UC Merced Bakery."
        ),
        MealCategory(
            id: "62daecc36c04ea001048a55d",
            name: "FoG Breakfast",
            order: 29,
            explanationText: "Field of Greens Breakfast — plant-forward and allergen-conscious morning selections."
        ),
        MealCategory(
            id: "61ed885a9be79300147d3898",
            name: "FoG Lunch & Dinner",
            order: 31,
            explanationText: "Field of Greens Lunch & Dinner — plant-based, wholesome grains, and seasonal produce."
        ),
        MealCategory(
            id: "61ed97b39be79300147d3d06",
            name: "CG Lunch & Dinner",
            order: 32,
            explanationText: "Common Grounds Lunch & Dinner — artisan deli sandwiches, wraps, and soups."
        ),
    ]

    public static let samplePavilionItems: [MenuItemSummary] = [
        MenuItemSummary(
            id: "6aa2b4e20cb70aee0229feeb",
            name: "BobCat Chicken Sandwich",
            description: "@Rufus: Burger or Vegan Pretzel Bun. Choice of Protein : Oven Fried Crispy Chicken or Plant-Base Chick'N Tenders with Curly Fries, Coleslaw and Adds.",
            menuNo: 33074,
            minmaxCaloriesRange: "260 - 1260",
            caloriesInfo: "960 Cal.",
            dietaryStatus: .safeMatch
        ),
        MenuItemSummary(
            id: "6aa2b6c0e5294a5a93e892d7",
            name: "Healthy Concepts!",
            description: "@Lake Wok : Protein Choice of Honey Ginger Glazed Salmon or Honey Ginger Glazed Tofu. Sides of Brown Rice Pilaf, Steamed Cauliflower, Roasted Potatoes, Maple Glaze Rainbow Carrots and Adds.",
            menuNo: 33075,
            minmaxCaloriesRange: "180 - 1060",
            caloriesInfo: "580 Cal.",
            dietaryStatus: .safeMatch
        ),
        MenuItemSummary(
            id: "6aa2b359e5294a5a93e87bf9",
            name: "Loaded Nachos",
            description: "@CASCABEL: Protein Choice of Pork Carnitas or Fable Shiitake Carnitas. Served with Tortilla Chips, Cheese Sauce, Pinto Beans and Adds.",
            menuNo: 33073,
            minmaxCaloriesRange: "70 - 860",
            caloriesInfo: "680 Cal.",
            dietaryStatus: .modifiableMatch
        ),
        MenuItemSummary(
            id: "6aa2b0fe0cb70aee0229e6a5",
            name: "Mediterranean Rice Bowl",
            description: "@Ciao : Pita Bread. Protein Choice of Mediterranean Marinated Beef or Mediterranean Plant-Base Steak w/ Veggies Served with Turmeric Yellow Rice, Sumac Spiced Potatoes and Adds.",
            menuNo: 33072,
            minmaxCaloriesRange: "190 - 1380",
            caloriesInfo: "870 Cal.",
            dietaryStatus: .safeMatch
        ),
        MenuItemSummary(
            id: "6aa17a510cb70aee0221730a",
            name: "Char Siu Bao Bun",
            description: "@Lake Wok : Protein Choice of Char Siu Pork or Plant Based Marinated Char Siu Bao on Char Siu Bao Bun; Served with Steamed Broccoli, Garlic green Beans and Adds.",
            menuNo: 33060,
            minmaxCaloriesRange: "240 - 920",
            caloriesInfo: "640 Cal.",
            dietaryStatus: .safeMatch
        ),
        MenuItemSummary(
            id: "6aa17c630cb70aee022180d7",
            name: "Chicken & Waffles",
            description: "@Rufus: Protein Choice of Crispy Chicken or Crispy Beyond Chick'N tender w/ Belgian Waffle, Scrambled Eggs With Sides of Hash Brown Triangles, Roasted Breakfast Vegetables.",
            menuNo: 33061,
            minmaxCaloriesRange: "310 - 1140",
            caloriesInfo: "790 Cal.",
            dietaryStatus: .modifiableMatch
        ),
    ]
}
