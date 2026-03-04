const baseUrl = "http://localhost:8081/api";

async function testFetch() {
    const loginRes = await fetch(`${baseUrl}/auth/signin`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ usernameOrEmail: "admin", password: "password" })
    });

    let token = null;
    if (!loginRes.ok) {
        const loginRes2 = await fetch(`${baseUrl}/auth/signin`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ usernameOrEmail: "admin_test1", password: "password" })
        });
        const data = await loginRes2.json();
        token = data.accessToken;
    } else {
        const data = await loginRes.json();
        token = data.accessToken;
    }

    const dicRes = await fetch(`${baseUrl}/dictionary/A`, {
        headers: { "Authorization": `Bearer ${token}` }
    });

    if (!dicRes.ok) {
        console.error(`Dictionary failed: ${dicRes.status}`);
        console.error(await dicRes.text());
    } else {
        console.log(`Dictionary OK`);
        console.log(await dicRes.json());
    }
}

testFetch();
