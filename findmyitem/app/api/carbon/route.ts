import { GoogleGenerativeAI } from "@google/generative-ai";
import { NextResponse } from "next/server";
import { type NextRequest } from 'next/server'
import dotenv from 'dotenv';
dotenv.config();

export async function GET(
  req: NextRequest
) {
  const item = req.nextUrl.searchParams.get("item") as string
  const apiKey = process.env.GEMINI_KEY
  console.log(apiKey)
  const genAI = new GoogleGenerativeAI(String(apiKey));


  const model = genAI.getGenerativeModel({
    model: "gemini-1.5-flash",
    generationConfig: {"responseMimeType": "application/json"},
  });
  
  const prompt = `Estimate the total carbon footprint of ${item} from production to retail, considering factors such as farming, processing, transportation, and packaging. Additionally, identify the most sustainable brand for this product based on its carbon footprint, ethical sourcing, and packaging sustainability. Use the following JSON schema:

  CarbonFootPrint = {
    "product": str,  // Name of the product
    "unit_of_product": str, // Standard measurement unit (e.g., kg, liter, piece)
    "number_of_units": str, // Quantity of product
    "carbon_footprint": number, // Total CO₂ equivalent emissions
    "unit_of_carbon" : str, // Measurement unit for carbon footprint (e.g., kg CO₂e)
    "sustainable_brand": str, // Name of the most sustainable brand (if not found, give a company you think is sustainable)
  }

  Return the result as a JSON object. If no data is available, estimate based on similar products. Ensure the response is structured correctly.`;
  const data = await model.generateContent(prompt)
  const result = await data.response.text()
  console.log(result)
  const jsonObject = JSON.parse(result);
  console.log(jsonObject)
 
  return NextResponse.json(jsonObject)
}