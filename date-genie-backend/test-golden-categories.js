const tests = [
  { city: 'NYC', query: 'dinner', budget: 100, radius: 10, categories: ['Food', 'Romantic'] },
  { city: 'LA', query: 'fun', budget: 50, radius: 15, categories: ['Fun'] },
  { city: 'Chicago', query: 'bar', budget: 75, radius: 5, categories: ['Bars/Drinks'] },
  { city: 'Austin', query: 'outdoor', budget: 0, radius: 20, categories: ['Nature'] },
  { city: 'San Diego', query: 'culture', budget: 100, radius: 10, categories: ['Cultural'] },
];

async function runTest() {
  console.log('Running Golden Set Test...\n');
  
  for (const test of tests) {
    const start = Date.now();
    const res = await fetch('http://localhost:3000/api/search', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(test),
    });
    
    const data = await res.json();
    const top3 = data.data.slice(0, 3);
    
    const chains = ['McDonald', 'Starbucks', 'Target', 'Walmart', 'Applebee', 'Chili'];
    const hasLocalGem = top3.some(v => !chains.some(chain => v.name.includes(chain)));
    const hasCategoryMatch = top3.some(v => v.selectedCategories.some(cat => test.categories.includes(cat)));
    
    console.log(`${test.city} - ${test.categories.join(' + ')}: ${
      hasLocalGem ? '✅ Local Gem' : '❌ Chain Detected'
    } | ${
      hasCategoryMatch ? '✅ Category Match' : '❌ Wrong Category'
    } (${Date.now() - start}ms)`);
  }
  
  console.log('\nGolden Set Complete ✅');
}

runTest().catch(console.error);