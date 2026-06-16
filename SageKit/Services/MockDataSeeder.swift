//
//  MockDataSeeder.swift
//  FinanceTracker
//

#if DEBUG
import Foundation
import SwiftData
import UIKit

// Budget reference: $5,000/month, 50/30/20 split
//   Needs:   $2,500
//   Wants:   $1,500
//   Savings: $1,000  ← never exceeded

public enum MockDataSeeder {

    public static func seed(into context: ModelContext) {
        // Guards against re-seeding an already-populated store
        let existingCount = (try? context.fetchCount(FetchDescriptor<Expense>())) ?? 0
        guard existingCount == 0 else { return }

        seedAppConfiguration()

        let cal = Calendar.current

        func date(_ month: Int, _ day: Int) -> Date {
            cal.date(from: DateComponents(year: 2026, month: month, day: day))!
        }

        let shopping      = ExpenseTag(name: "Shopping",          uiColor: .systemYellow, emoji: "🛍️")
        let dining        = ExpenseTag(name: "Dining",            uiColor: .systemOrange, emoji: "🍽️")
        let entertainment = ExpenseTag(name: "Entertainment",     uiColor: .systemPink,   emoji: "🍿")
        let bills         = ExpenseTag(name: "Bills & Utilities", uiColor: .systemBlue,   emoji: "🏠")
        let groceries     = ExpenseTag(name: "Groceries",         uiColor: .systemGreen,  emoji: "🥗")
        let subscriptions = ExpenseTag(name: "Subscriptions",     uiColor: .systemTeal,   emoji: "💻")
        let travel        = ExpenseTag(name: "Travel",            uiColor: .systemPurple, emoji: "✈️")
        let other         = ExpenseTag(name: "Other",             uiColor: .systemGray,   emoji: "🔖")

        for tag in [shopping, dining, entertainment, bills, groceries, subscriptions, travel, other] {
            context.insert(tag)
        }

        var all: [Expense] = []

        // MARK: - January 2026
        // Needs: $2,163.75 | Wants: $851.63 | Savings: $800.00

        all += [
            // Needs
            Expense(name: "Rent",                  amount: 1400.00, category: .needs,   date: date(1,  1), tag: bills),
            Expense(name: "Car Insurance",          amount: 148.50,  category: .needs,   date: date(1,  3), tag: bills),
            Expense(name: "Health Insurance",       amount: 180.00,  category: .needs,   date: date(1,  5), tag: bills),
            Expense(name: "Phone Bill",             amount: 65.00,   category: .needs,   date: date(1,  7), tag: bills),
            Expense(name: "Internet",               amount: 55.00,   category: .needs,   date: date(1,  8), tag: bills),
            Expense(name: "Grocery Run",            amount: 87.45,   category: .needs,   date: date(1,  9), tag: groceries),
            Expense(name: "Gas Station",            amount: 44.20,   category: .needs,   date: date(1, 11), tag: other),
            Expense(name: "Grocery Run",            amount: 91.30,   category: .needs,   date: date(1, 18), tag: groceries),
            Expense(name: "Doctor Copay",           amount: 30.00,   category: .needs,   date: date(1, 22), tag: other),
            Expense(name: "Gas Station",            amount: 39.80,   category: .needs,   date: date(1, 27), tag: other),
            Expense(name: "Pharmacy",               amount: 22.50,   category: .needs,   date: date(1, 29), tag: other),

            // Wants
            Expense(name: "Netflix",                amount: 15.99,   category: .wants,   date: date(1,  2), tag: subscriptions),
            Expense(name: "Spotify",                amount: 9.99,    category: .wants,   date: date(1,  2), tag: subscriptions),
            Expense(name: "iCloud+",                amount: 2.99,    category: .wants,   date: date(1,  2), tag: subscriptions),
            Expense(name: "Gym Membership",         amount: 45.00,   category: .wants,   date: date(1,  2), tag: other),
            Expense(name: "Hulu",                   amount: 17.99,   category: .wants,   date: date(1,  2), tag: subscriptions),
            Expense(name: "New Year's Dinner",      amount: 88.00,   category: .wants,   date: date(1,  3), tag: dining),
            Expense(name: "Coffee",                 amount: 6.50,    category: .wants,   date: date(1,  5), tag: dining),
            Expense(name: "Dinner – Olive Garden",  amount: 52.40,   category: .wants,   date: date(1,  6), tag: dining),
            Expense(name: "Winter Jacket",          amount: 89.99,   category: .wants,   date: date(1,  8), tag: shopping),
            Expense(name: "Coffee",                 amount: 7.25,    category: .wants,   date: date(1, 12), tag: dining),
            Expense(name: "Happy Hour",             amount: 45.00,   category: .wants,   date: date(1, 13), tag: dining),
            Expense(name: "Cinema Tickets",         amount: 28.00,   category: .wants,   date: date(1, 14), tag: entertainment),
            Expense(name: "Sweaters & Scarf",       amount: 74.50,   category: .wants,   date: date(1, 16), tag: shopping),
            Expense(name: "Movie Snacks",           amount: 14.00,   category: .wants,   date: date(1, 16), tag: entertainment),
            Expense(name: "Amazon – Accessories",   amount: 47.30,   category: .wants,   date: date(1, 17), tag: shopping),
            Expense(name: "Sushi Dinner",           amount: 68.00,   category: .wants,   date: date(1, 19), tag: dining),
            Expense(name: "Lunch with Friends",     amount: 34.00,   category: .wants,   date: date(1, 20), tag: dining),
            Expense(name: "Amazon – Smart Gadget",  amount: 38.99,   category: .wants,   date: date(1, 21), tag: shopping),
            Expense(name: "Haircut",                amount: 35.00,   category: .wants,   date: date(1, 24), tag: other),
            Expense(name: "Video Game",             amount: 69.99,   category: .wants,   date: date(1, 25), tag: entertainment),
            Expense(name: "Bar with Friends",       amount: 52.00,   category: .wants,   date: date(1, 26), tag: dining),
            Expense(name: "Coffee",                 amount: 8.75,    category: .wants,   date: date(1, 27), tag: dining),

            // Savings
            Expense(name: "Emergency Fund",         amount: 300.00,  category: .savings, date: date(1,  1), tag: other),
            Expense(name: "Investment Transfer",    amount: 500.00,  category: .savings, date: date(1, 15), tag: other),
        ]

        // MARK: - February 2026
        // Needs: $2,170.80 | Wants: $831.88 | Savings: $800.00

        all += [
            // Needs
            Expense(name: "Rent",                   amount: 1400.00, category: .needs,   date: date(2,  1), tag: bills),
            Expense(name: "Car Insurance",          amount: 148.50,  category: .needs,   date: date(2,  3), tag: bills),
            Expense(name: "Health Insurance",       amount: 180.00,  category: .needs,   date: date(2,  5), tag: bills),
            Expense(name: "Phone Bill",             amount: 65.00,   category: .needs,   date: date(2,  7), tag: bills),
            Expense(name: "Internet",               amount: 55.00,   category: .needs,   date: date(2,  8), tag: bills),
            Expense(name: "Grocery Run",            amount: 79.90,   category: .needs,   date: date(2,  7), tag: groceries),
            Expense(name: "Gas Station",            amount: 41.00,   category: .needs,   date: date(2, 10), tag: other),
            Expense(name: "Grocery Run",            amount: 95.60,   category: .needs,   date: date(2, 16), tag: groceries),
            Expense(name: "Gas Station",            amount: 37.50,   category: .needs,   date: date(2, 24), tag: other),
            Expense(name: "Grocery Run",            amount: 68.30,   category: .needs,   date: date(2, 28), tag: groceries),

            // Wants
            Expense(name: "Netflix",                amount: 15.99,   category: .wants,   date: date(2,  2), tag: subscriptions),
            Expense(name: "Spotify",                amount: 9.99,    category: .wants,   date: date(2,  2), tag: subscriptions),
            Expense(name: "iCloud+",                amount: 2.99,    category: .wants,   date: date(2,  2), tag: subscriptions),
            Expense(name: "Gym Membership",         amount: 45.00,   category: .wants,   date: date(2,  2), tag: other),
            Expense(name: "Hulu",                   amount: 17.99,   category: .wants,   date: date(2,  2), tag: subscriptions),
            Expense(name: "Coffee",                 amount: 7.25,    category: .wants,   date: date(2,  5), tag: dining),
            Expense(name: "Concert Tickets",        amount: 75.00,   category: .wants,   date: date(2,  8), tag: entertainment),
            Expense(name: "Clothes – Gap",          amount: 62.40,   category: .wants,   date: date(2, 10), tag: shopping),
            Expense(name: "Coffee",                 amount: 8.50,    category: .wants,   date: date(2, 12), tag: dining),
            Expense(name: "Flowers",                amount: 45.00,   category: .wants,   date: date(2, 13), tag: shopping),
            Expense(name: "Valentine's Dinner",     amount: 98.50,   category: .wants,   date: date(2, 14), tag: dining),
            Expense(name: "Candles & Decor",        amount: 45.00,   category: .wants,   date: date(2, 16), tag: shopping),
            Expense(name: "Lunch",                  amount: 16.50,   category: .wants,   date: date(2, 18), tag: dining),
            Expense(name: "Shoes – New Balance",    amount: 89.99,   category: .wants,   date: date(2, 20), tag: shopping),
            Expense(name: "Sports Bar",             amount: 58.00,   category: .wants,   date: date(2, 21), tag: dining),
            Expense(name: "Sushi Night",            amount: 44.80,   category: .wants,   date: date(2, 21), tag: dining),
            Expense(name: "Haircut",                amount: 35.00,   category: .wants,   date: date(2, 22), tag: other),
            Expense(name: "Amazon – Small Order",   amount: 29.99,   category: .wants,   date: date(2, 25), tag: shopping),
            Expense(name: "Board Game",             amount: 34.99,   category: .wants,   date: date(2, 26), tag: entertainment),
            Expense(name: "Movie Night",            amount: 24.00,   category: .wants,   date: date(2, 28), tag: entertainment),
            Expense(name: "Spa Day",                amount: 65.00,   category: .wants,   date: date(2, 22), tag: other),

            // Savings
            Expense(name: "Emergency Fund",         amount: 300.00,  category: .savings, date: date(2,  1), tag: other),
            Expense(name: "Investment Transfer",    amount: 500.00,  category: .savings, date: date(2, 15), tag: other),
        ]

        // MARK: - March 2026
        // Needs: $2,287.65 | Wants: $949.78 | Savings: $1,000.00 (at limit)

        all += [
            // Needs
            Expense(name: "Rent",                   amount: 1400.00, category: .needs,   date: date(3,  1), tag: bills),
            Expense(name: "Car Insurance",          amount: 148.50,  category: .needs,   date: date(3,  3), tag: bills),
            Expense(name: "Health Insurance",       amount: 180.00,  category: .needs,   date: date(3,  5), tag: bills),
            Expense(name: "Phone Bill",             amount: 65.00,   category: .needs,   date: date(3,  7), tag: bills),
            Expense(name: "Internet",               amount: 55.00,   category: .needs,   date: date(3,  8), tag: bills),
            Expense(name: "Grocery Run",            amount: 92.15,   category: .needs,   date: date(3,  6), tag: groceries),
            Expense(name: "Gas Station",            amount: 46.30,   category: .needs,   date: date(3,  9), tag: other),
            Expense(name: "Grocery Run",            amount: 84.70,   category: .needs,   date: date(3, 15), tag: groceries),
            Expense(name: "Dentist",                amount: 95.00,   category: .needs,   date: date(3, 18), tag: other),
            Expense(name: "Gas Station",            amount: 43.20,   category: .needs,   date: date(3, 23), tag: other),
            Expense(name: "Grocery Run",            amount: 77.80,   category: .needs,   date: date(3, 28), tag: groceries),

            // Wants
            Expense(name: "Netflix",                amount: 15.99,   category: .wants,   date: date(3,  2), tag: subscriptions),
            Expense(name: "Spotify",                amount: 9.99,    category: .wants,   date: date(3,  2), tag: subscriptions),
            Expense(name: "iCloud+",                amount: 2.99,    category: .wants,   date: date(3,  2), tag: subscriptions),
            Expense(name: "Gym Membership",         amount: 45.00,   category: .wants,   date: date(3,  2), tag: other),
            Expense(name: "Hulu",                   amount: 17.99,   category: .wants,   date: date(3,  2), tag: subscriptions),
            Expense(name: "Adobe Creative Cloud",   amount: 54.99,   category: .wants,   date: date(3,  5), tag: subscriptions),
            Expense(name: "Brunch",                 amount: 38.50,   category: .wants,   date: date(3,  8), tag: dining),
            Expense(name: "Coffee",                 amount: 5.75,    category: .wants,   date: date(3, 10), tag: dining),
            Expense(name: "Plant & Decor",          amount: 65.00,   category: .wants,   date: date(3, 12), tag: shopping),
            Expense(name: "Spring Clothing",        amount: 134.00,  category: .wants,   date: date(3, 12), tag: shopping),
            Expense(name: "Lunch",                  amount: 21.50,   category: .wants,   date: date(3, 14), tag: dining),
            Expense(name: "Ramen Dinner",           amount: 34.00,   category: .wants,   date: date(3, 17), tag: dining),
            Expense(name: "Taco Tuesday",           amount: 27.60,   category: .wants,   date: date(3, 18), tag: dining),
            Expense(name: "Theater Tickets",        amount: 85.00,   category: .wants,   date: date(3, 19), tag: entertainment),
            Expense(name: "Museum Visit",           amount: 22.00,   category: .wants,   date: date(3, 21), tag: entertainment),
            Expense(name: "Mini Golf",              amount: 24.00,   category: .wants,   date: date(3, 22), tag: entertainment),
            Expense(name: "Happy Hour",             amount: 55.00,   category: .wants,   date: date(3, 23), tag: dining),
            Expense(name: "Coffee",                 amount: 8.50,    category: .wants,   date: date(3, 24), tag: dining),
            Expense(name: "New Sneakers",           amount: 79.99,   category: .wants,   date: date(3, 27), tag: shopping),
            Expense(name: "Bookstore",              amount: 38.99,   category: .wants,   date: date(3, 27), tag: entertainment),
            Expense(name: "Italian Dinner",         amount: 72.00,   category: .wants,   date: date(3, 28), tag: dining),
            Expense(name: "Haircut",                amount: 35.00,   category: .wants,   date: date(3, 29), tag: other),
            Expense(name: "Amazon – Misc",          amount: 56.00,   category: .wants,   date: date(3, 30), tag: shopping),

            // Savings  ($1,000 — at limit, not over)
            Expense(name: "Emergency Fund",         amount: 300.00,  category: .savings, date: date(3,  1), tag: other),
            Expense(name: "Investment Transfer",    amount: 500.00,  category: .savings, date: date(3, 15), tag: other),
            Expense(name: "Vacation Fund",          amount: 200.00,  category: .savings, date: date(3, 20), tag: travel),
        ]

        // MARK: - April 2026  (travel month)
        // Needs: $2,104.00 | Wants: $1,460.19 | Savings: $600.00

        all += [
            // Needs
            Expense(name: "Rent",                   amount: 1400.00, category: .needs,   date: date(4,  1), tag: bills),
            Expense(name: "Car Insurance",          amount: 148.50,  category: .needs,   date: date(4,  3), tag: bills),
            Expense(name: "Health Insurance",       amount: 180.00,  category: .needs,   date: date(4,  5), tag: bills),
            Expense(name: "Phone Bill",             amount: 65.00,   category: .needs,   date: date(4,  7), tag: bills),
            Expense(name: "Internet",               amount: 55.00,   category: .needs,   date: date(4,  8), tag: bills),
            Expense(name: "Grocery Run",            amount: 88.00,   category: .needs,   date: date(4,  5), tag: groceries),
            Expense(name: "Gas Station",            amount: 50.00,   category: .needs,   date: date(4,  8), tag: other),
            Expense(name: "Grocery Run",            amount: 72.50,   category: .needs,   date: date(4, 22), tag: groceries),
            Expense(name: "Gas Station",            amount: 45.00,   category: .needs,   date: date(4, 27), tag: other),

            // Wants
            Expense(name: "Netflix",                amount: 15.99,   category: .wants,   date: date(4,  2), tag: subscriptions),
            Expense(name: "Spotify",                amount: 9.99,    category: .wants,   date: date(4,  2), tag: subscriptions),
            Expense(name: "iCloud+",                amount: 2.99,    category: .wants,   date: date(4,  2), tag: subscriptions),
            Expense(name: "Gym Membership",         amount: 45.00,   category: .wants,   date: date(4,  2), tag: other),
            Expense(name: "Hulu",                   amount: 17.99,   category: .wants,   date: date(4,  2), tag: subscriptions),
            Expense(name: "Adobe Creative Cloud",   amount: 54.99,   category: .wants,   date: date(4,  5), tag: subscriptions),
            Expense(name: "Coffee",                 amount: 6.50,    category: .wants,   date: date(4,  7), tag: dining),
            Expense(name: "Flight to Miami",        amount: 280.00,  category: .wants,   date: date(4, 10), tag: travel),
            Expense(name: "Hotel – 4 nights",       amount: 420.00,  category: .wants,   date: date(4, 11), tag: travel),
            Expense(name: "Sunscreen & Beach Gear", amount: 42.00,   category: .wants,   date: date(4, 11), tag: shopping),
            Expense(name: "Beach Dinner",           amount: 76.00,   category: .wants,   date: date(4, 12), tag: dining),
            Expense(name: "Snorkeling Tour",        amount: 65.00,   category: .wants,   date: date(4, 13), tag: travel),
            Expense(name: "Car Rental",             amount: 85.00,   category: .wants,   date: date(4, 13), tag: travel),
            Expense(name: "Seafood Restaurant",     amount: 88.00,   category: .wants,   date: date(4, 14), tag: dining),
            Expense(name: "Souvenir Shopping",      amount: 55.00,   category: .wants,   date: date(4, 14), tag: shopping),
            Expense(name: "Airport Lunch",          amount: 18.50,   category: .wants,   date: date(4, 15), tag: dining),
            Expense(name: "Dinner – Steakhouse",    amount: 85.00,   category: .wants,   date: date(4, 24), tag: dining),
            Expense(name: "Happy Hour",             amount: 45.00,   category: .wants,   date: date(4, 28), tag: dining),
            Expense(name: "Amazon – Post-trip",     amount: 39.99,   category: .wants,   date: date(4, 29), tag: shopping),
            Expense(name: "Coffee",                 amount: 7.25,    category: .wants,   date: date(4, 29), tag: dining),

            // Savings  (reduced — travel month)
            Expense(name: "Emergency Fund",         amount: 300.00,  category: .savings, date: date(4,  1), tag: other),
            Expense(name: "Investment Transfer",    amount: 300.00,  category: .savings, date: date(4, 15), tag: other),
        ]

        // MARK: - May 2026
        // Needs: $2,234.40 | Wants: $908.47 | Savings: $950.00

        all += [
            // Needs
            Expense(name: "Rent",                   amount: 1400.00, category: .needs,   date: date(5,  1), tag: bills),
            Expense(name: "Car Insurance",          amount: 148.50,  category: .needs,   date: date(5,  3), tag: bills),
            Expense(name: "Health Insurance",       amount: 180.00,  category: .needs,   date: date(5,  5), tag: bills),
            Expense(name: "Phone Bill",             amount: 65.00,   category: .needs,   date: date(5,  7), tag: bills),
            Expense(name: "Internet",               amount: 55.00,   category: .needs,   date: date(5,  8), tag: bills),
            Expense(name: "Grocery Run",            amount: 96.40,   category: .needs,   date: date(5,  4), tag: groceries),
            Expense(name: "Gas Station",            amount: 42.80,   category: .needs,   date: date(5,  7), tag: other),
            Expense(name: "Grocery Run",            amount: 82.90,   category: .needs,   date: date(5, 13), tag: groceries),
            Expense(name: "Prescription",           amount: 18.00,   category: .needs,   date: date(5, 17), tag: other),
            Expense(name: "Grocery Run",            amount: 105.20,  category: .needs,   date: date(5, 24), tag: groceries),
            Expense(name: "Gas Station",            amount: 40.60,   category: .needs,   date: date(5, 27), tag: other),

            // Wants
            Expense(name: "Netflix",                amount: 15.99,   category: .wants,   date: date(5,  2), tag: subscriptions),
            Expense(name: "Spotify",                amount: 9.99,    category: .wants,   date: date(5,  2), tag: subscriptions),
            Expense(name: "iCloud+",                amount: 2.99,    category: .wants,   date: date(5,  2), tag: subscriptions),
            Expense(name: "Gym Membership",         amount: 45.00,   category: .wants,   date: date(5,  2), tag: other),
            Expense(name: "Hulu",                   amount: 17.99,   category: .wants,   date: date(5,  2), tag: subscriptions),
            Expense(name: "Adobe Creative Cloud",   amount: 54.99,   category: .wants,   date: date(5,  5), tag: subscriptions),
            Expense(name: "Coffee",                 amount: 6.25,    category: .wants,   date: date(5,  6), tag: dining),
            Expense(name: "Mother's Day Brunch",    amount: 65.00,   category: .wants,   date: date(5, 11), tag: dining),
            Expense(name: "Gift for Mom",           amount: 50.00,   category: .wants,   date: date(5, 11), tag: shopping),
            Expense(name: "Coffee",                 amount: 8.50,    category: .wants,   date: date(5, 14), tag: dining),
            Expense(name: "Bowling Night",          amount: 32.00,   category: .wants,   date: date(5, 18), tag: entertainment),
            Expense(name: "Wine Bar",               amount: 55.00,   category: .wants,   date: date(5, 20), tag: dining),
            Expense(name: "Patio Furniture",        amount: 149.99,  category: .wants,   date: date(5, 21), tag: shopping),
            Expense(name: "Comedy Show",            amount: 48.00,   category: .wants,   date: date(5, 22), tag: entertainment),
            Expense(name: "Dinner – Thai Place",    amount: 41.50,   category: .wants,   date: date(5, 23), tag: dining),
            Expense(name: "Summer Clothes",         amount: 89.99,   category: .wants,   date: date(5, 24), tag: shopping),
            Expense(name: "Amazon – Electronics",   amount: 78.00,   category: .wants,   date: date(5, 25), tag: shopping),
            Expense(name: "Kindle Book",            amount: 12.99,   category: .wants,   date: date(5, 26), tag: entertainment),
            Expense(name: "Haircut",                amount: 35.00,   category: .wants,   date: date(5, 27), tag: other),
            Expense(name: "Tacos & Drinks",         amount: 29.80,   category: .wants,   date: date(5, 30), tag: dining),
            Expense(name: "Coffee",                 amount: 7.50,    category: .wants,   date: date(5, 30), tag: dining),
            Expense(name: "Bar",                    amount: 52.00,   category: .wants,   date: date(5, 31), tag: dining),

            // Savings
            Expense(name: "Emergency Fund",         amount: 300.00,  category: .savings, date: date(5,  1), tag: other),
            Expense(name: "Investment Transfer",    amount: 500.00,  category: .savings, date: date(5, 15), tag: other),
            Expense(name: "Vacation Fund",          amount: 150.00,  category: .savings, date: date(5, 20), tag: travel),
        ]

        // MARK: - June 2026  (current month, through June 11)
        // Needs: $1,984.45 | Wants: $355.44 | Savings: $300.00

        all += [
            // Needs
            Expense(name: "Rent",                   amount: 1400.00, category: .needs,   date: date(6,  1), tag: bills),
            Expense(name: "Car Insurance",          amount: 148.50,  category: .needs,   date: date(6,  3), tag: bills),
            Expense(name: "Health Insurance",       amount: 180.00,  category: .needs,   date: date(6,  5), tag: bills),
            Expense(name: "Phone Bill",             amount: 65.00,   category: .needs,   date: date(6,  7), tag: bills),
            Expense(name: "Internet",               amount: 55.00,   category: .needs,   date: date(6,  8), tag: bills),
            Expense(name: "Grocery Run",            amount: 88.75,   category: .needs,   date: date(6,  6), tag: groceries),
            Expense(name: "Gas Station",            amount: 47.20,   category: .needs,   date: date(6,  9), tag: other),

            // Wants
            Expense(name: "Netflix",                amount: 15.99,   category: .wants,   date: date(6,  2), tag: subscriptions),
            Expense(name: "Spotify",                amount: 9.99,    category: .wants,   date: date(6,  2), tag: subscriptions),
            Expense(name: "iCloud+",                amount: 2.99,    category: .wants,   date: date(6,  2), tag: subscriptions),
            Expense(name: "Gym Membership",         amount: 45.00,   category: .wants,   date: date(6,  2), tag: other),
            Expense(name: "Hulu",                   amount: 17.99,   category: .wants,   date: date(6,  2), tag: subscriptions),
            Expense(name: "Adobe Creative Cloud",   amount: 54.99,   category: .wants,   date: date(6,  5), tag: subscriptions),
            Expense(name: "Coffee",                 amount: 7.50,    category: .wants,   date: date(6,  4), tag: dining),
            Expense(name: "Rooftop Bar",            amount: 58.00,   category: .wants,   date: date(6,  7), tag: dining),
            Expense(name: "Coffee",                 amount: 8.50,    category: .wants,   date: date(6,  9), tag: dining),
            Expense(name: "Summer Shorts",          amount: 39.99,   category: .wants,   date: date(6, 10), tag: shopping),
            Expense(name: "Lunch – Deli",           amount: 14.50,   category: .wants,   date: date(6, 10), tag: dining),
            Expense(name: "Escape Room",            amount: 28.00,   category: .wants,   date: date(6, 11), tag: entertainment),
            Expense(name: "Amazon Order",           amount: 52.00,   category: .wants,   date: date(6, 11), tag: shopping),

            // Savings
            Expense(name: "Emergency Fund",         amount: 300.00,  category: .savings, date: date(6,  1), tag: other),
        ]

        for expense in all {
            context.insert(expense)
        }
    }

    // Seeds budget configuration into shared UserDefaults so the app shows
    // correct budget meters without requiring manual onboarding in DEBUG.
    // Writes to UserDefaults.standard (isolated per bundle ID) so the debug
    // build's config never touches the shared app group used by the production app.
    private static func seedAppConfiguration() {
        let defaults = UserDefaults.standard
        defaults.set(5000, forKey: "totalMonthlyIncome")
        defaults.set(0.5,  forKey: "needsPercent")
        defaults.set(0.3,  forKey: "wantsPercent")
        defaults.set(0.2,  forKey: "savingsPercent")
        defaults.set(true, forKey: "hasOpenedAppOnce")
    }
}
#endif
