const testPayload = {
  city: "NYC",
  query: "date night",
  budget: 100,
  radius: 10,
  categories: ["Romantic", "Food"],
  userId: "test_user_123"
};

console.log('Sending request with payload:', JSON.stringify(testPayload, null, 2));

fetch('http://localhost:3000/api/search', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(testPayload)
})
.then(async res => {
  const text = await res.text();
  console.log('Raw response:', text);
  return JSON.parse(text);
})
.then(data => {
  console.log('\n✅ Parsed response:');
  console.log('Success:', data.success);
  console.log('Source:', data.source);
  console.log('Latency:', data.latency + 'ms');
  console.log('Results:', data.data?.length || 0, 'venues');
  if (data.data?.length > 0) {
    console.log('\n🏆 Top venue:');
    console.log('Name:', data.data[0].name);
    console.log('Categories:', data.data[0].selectedCategories);
    console.log('Score:', data.data[0].dateabilityScore);
    console.log('Pitch:', data.data[0].aiPitch);
  }
  process.exit(0);
})
.catch(err => {
  console.error('❌ Error:', err.message);
  process.exit(1);
});