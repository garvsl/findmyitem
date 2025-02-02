// TODO : ShadCN needed

// import React, { useState } from "react";
// import { Button } from "@/components/ui/button";
// import {
//   Card,
//   CardContent,
//   CardFooter,
//   CardHeader,
//   CardTitle,
// } from "@/components/ui/card";
// import { Input } from "@/components/ui/input";
// import { Label } from "@/components/ui/label";

// // Type for product information
// interface ProductInfo {
//   name: string;
//   section: string;
//   coordinates: {
//     x: number;
//     y: number;
//     z: number;
//   };
// }

// // Mock database of products
// const productDatabase: Record<string, ProductInfo> = {
//   banana: {
//     name: "Organic Bananas",
//     section: "Produce",
//     coordinates: { x: 60, y: 0, z: 60 },
//   },
//   milk: {
//     name: "Whole Milk",
//     section: "Dairy",
//     coordinates: { x: 200, y: 0, z: 60 },
//   },
//   bread: {
//     name: "Whole Wheat Bread",
//     section: "Bakery",
//     coordinates: { x: 660, y: 0, z: 60 },
//   },
// };

// const ProductActions = () => {
//   const [productId, setProductId] = useState("");
//   const [productInfo, setProductInfo] = useState<ProductInfo | null>(null);
//   const [error, setError] = useState("");

//   const handleSubmit = (e: React.FormEvent) => {
//     e.preventDefault();
//     const product = productDatabase[productId.toLowerCase()];

//     if (product) {
//       setProductInfo(product);
//       setError("");
//     } else {
//       setProductInfo(null);
//       setError("Product not found. Please try again.");
//     }
//   };

//   const handleAddToCart = () => {
//     // This will be implemented by your teammate
//     alert("Add to cart functionality will be implemented by teammate");
//   };

//   const handleGoToItem = () => {
//     if (productInfo) {
//       // Create URL with search parameters
//       const params = new URLSearchParams({
//         product: productInfo.name,
//         section: productInfo.section,
//         x: productInfo.coordinates.x.toString(),
//         y: productInfo.coordinates.y.toString(),
//         z: productInfo.coordinates.z.toString(),
//       });

//       // Navigate to AR view using standard window.location
//       window.location.href = `/ar-navigation?${params.toString()}`;
//     }
//   };

//   return (
//     <Card className="w-full max-w-md mx-auto">
//       <CardHeader>
//         <CardTitle>Find Product</CardTitle>
//       </CardHeader>

//       <CardContent>
//         <form onSubmit={handleSubmit} className="space-y-4">
//           <div className="space-y-2">
//             <Label htmlFor="productId">Enter Product Name</Label>
//             <Input
//               id="productId"
//               type="text"
//               value={productId}
//               onChange={(e) => setProductId(e.target.value)}
//               placeholder="e.g., banana, milk, bread"
//               className="w-full"
//             />
//           </div>

//           <Button type="submit" className="w-full">
//             Search
//           </Button>
//         </form>

//         {error && <p className="text-red-500 mt-4">{error}</p>}

//         {productInfo && (
//           <div className="mt-6 p-4 bg-gray-50 rounded-lg">
//             <h3 className="font-semibold mb-2">{productInfo.name}</h3>
//             <p className="text-gray-600">Section: {productInfo.section}</p>
//           </div>
//         )}
//       </CardContent>

//       {productInfo && (
//         <CardFooter className="flex gap-4">
//           <Button
//             onClick={handleAddToCart}
//             variant="outline"
//             className="flex-1"
//           >
//             Add Item
//           </Button>

//           <Button onClick={handleGoToItem} className="flex-1">
//             Go to Item
//           </Button>
//         </CardFooter>
//       )}
//     </Card>
//   );
// };

// export default ProductActions;
