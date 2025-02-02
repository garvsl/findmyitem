import { GoogleGenerativeAI } from "@google/generative-ai";
import { NextResponse } from "next/server";
import { type NextRequest } from 'next/server'
import dotenv from 'dotenv';

dotenv.config();

function getCurrentDate() {
  return new Date().toISOString().split("T")[0]; 
}

const database = [
  {
    "product": "Beef",
    "unit_of_product": "kg",
    "number_of_units": "1",
    "carbon_footprint": 27,
    "unit_of_carbon": "kg CO2e",
    "date": "2024-01-15"
  },
  {
    "product": "Chicken",
    "unit_of_product": "kg",
    "number_of_units": "1",
    "carbon_footprint": 6.9,
    "unit_of_carbon": "kg CO2e",
    "date": "2024-02-10"
  },
  {
    "product": "Cheese",
    "unit_of_product": "kg",
    "number_of_units": "1",
    "carbon_footprint": 13.5,
    "unit_of_carbon": "kg CO2e",
    "date": "2024-03-05"
  },
  {
    "product": "Rice",
    "unit_of_product": "kg",
    "number_of_units": "1",
    "carbon_footprint": 4.5,
    "unit_of_carbon": "kg CO2e",
    "date": "2024-04-20"
  },
  {
    "product": "Eggs",
    "unit_of_product": "dozen",
    "number_of_units": "1",
    "carbon_footprint": 3.8,
    "unit_of_carbon": "kg CO2e",
    "date": "2024-05-15"
  },
  {
    "product": "Milk",
    "unit_of_product": "liters",
    "number_of_units": "1",
    "carbon_footprint": 3.2,
    "unit_of_carbon": "kg CO2e",
    "date": "2024-06-25"
  },
  {
    "product": "Lentils",
    "unit_of_product": "kg",
    "number_of_units": "1",
    "carbon_footprint": 0.9,
    "unit_of_carbon": "kg CO2e",
    "date": "2024-07-10"
  },
  {
    "product": "Tomatoes",
    "unit_of_product": "kg",
    "number_of_units": "1",
    "carbon_footprint": 2.1,
    "unit_of_carbon": "kg CO2e",
    "date": "2024-08-18"
  },
  {
    "product": "Potatoes",
    "unit_of_product": "kg",
    "number_of_units": "1",
    "carbon_footprint": 0.5,
    "unit_of_carbon": "kg CO2e",
    "date": "2024-09-05"
  },
  {
    "product": "Apples",
    "unit_of_product": "kg",
    "number_of_units": "1",
    "carbon_footprint": 0.4,
    "unit_of_carbon": "kg CO2e",
    "date": "2024-10-12"
  }
];

export default database

export async function GET(
  req: NextRequest
) {
  const item = req.nextUrl.searchParams.get("item") as string;
  const apiKey = process.env.GEMINI_KEY;
  console.log(apiKey);
  const genAI = new GoogleGenerativeAI(String(apiKey));

  const model = genAI.getGenerativeModel({
    model: "gemini-1.5-flash",
    generationConfig: { "responseMimeType": "application/json" },
  });

  const currentDate = getCurrentDate();

  const prompt = `Estimate the total carbon footprint of ${item} from production to retail, considering factors such as farming, processing, transportation, and packaging. Additionally, identify the most sustainable brand for this product based on its carbon footprint, ethical sourcing, and packaging sustainability. Use the following JSON schema:

  CarbonFootPrint = {
    "product": str,  // Name of the product
    "unit_of_product": str, // Standard measurement unit (e.g., kg, liter, piece)
    "number_of_units": str, // Quantity of product
    "carbon_footprint": number, // Total CO₂ equivalent emissions
    "unit_of_carbon" : str, // Measurement unit for carbon footprint (e.g., kg CO₂e)
    "sustainable_brand": str, // Name of the most sustainable brand (if not found, give a company you think is sustainable)
    "date": "${currentDate}" // Use today's date
  }

  Return the result as a JSON object. If no data is available, estimate based on similar products. Ensure the response is structured correctly.`;

  const data = await model.generateContent(prompt);
  const result = await data.response.text();
  console.log(result);
  
  const jsonObject = JSON.parse(result);
  console.log(jsonObject);

  database.push(jsonObject); 
  
  return NextResponse.json(jsonObject);
}
