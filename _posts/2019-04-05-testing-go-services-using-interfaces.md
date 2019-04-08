---
layout: post
title:  "Testing Go services using interfaces"
authors:
  - "Sebastian Coetzee"
excerpt: >
  Time to share some strategies for creating testable Go services using interfaces and generated mocks.
---

## Table of Contents
{:.no_toc}

1. Automatic Table of Contents Here
{:toc}

For the past year at [Deliveroo](https://deliveroo.co.uk/) I've been using [Go](https://golang.org/) almost exclusively. It's pretty simple and easy to understand, yet it's fast and productive to build with.

As software engineers, we need to have confidence that the solutions we put into production are of the highest quality. This doesn't only allow us to sleep better at night, but it's also important for the business to have faith in the quality of the product. One of the most effective ways to ensure a high quality is by writing software in such a way that it can be properly tested.

## Defining the goal posts

Let's look at an example of a service we would find in a microservices architecture such as the one at [Deliveroo](https://deliveroo.co.uk/).

The code referenced in this example is available on [Github](https://github.com/SebastianCoetzee/blog-order-service-example). Please feel free to clone the repo if you want to follow along.

The service shall be called the `OrderService` and it will be responsible for showing users a history of their orders. The `OrderService` shall have only one endpoint. Here is a description of the endpoint and an example response:

Request URL: `GET /users/:id/orders`

Response 200 (application/json):

```json
[
  {
    "id": 6,
    "restaurant": {
      "id": 3,
      "name": "Nando's"
    },
    "total": 2300,
    "currency_code": "GBP",
    "placed_at": "2019-03-30T08:35:30.0108Z"
  },
  {
    "id": 3,
    "restaurant": {
      "id": 7,
      "name": "KFC"
    },
    "total": 1000,
    "currency_code": "GBP",
    "placed_at": "2019-03-27T08:35:30.0108Z"
  }
]
```

For simplicity, we will ignore where the user's information is stored. At a high level, the system can be described by this diagram:

![Basic system architecture](/images/posts/testing-go-services-using-interfaces/order-service-example.png)

## Planning for testability

In order to create testable web services, we need to layer the design in a way that makes sense. The idea is to separate the concerns. Dependencies should be interfaces rather than concrete implementations.

The service should be split into the following layers:

- Data access repositories - interact directly with the database
- External API clients - call out to external services
- Services - contain the business logic
- Handlers - accept requests and builds the repsonses

## Defining the data model

There are essentially two entities that are required: `Order` and `Restaurant`. They are defined as follows:

```go
// Order is the model representation of an order in the data model.
type Order struct {
	ID           int         `json:"id"`
	UserID       int         `json:"-"`
	RestaurantID int         `json:"-"`
	Restaurant   *Restaurant `json:"restaurant" sql:"-"`
	Total        int         `json:"total"`
	CurrencyCode string      `json:"currency_code"`
	PlacedAt     time.Time   `json:"placed_at"`
}

// Orders is a slice of Order pointers.
type Orders []*Order
```

```go
// Restaurant is the model representation of a restaurant. Restaurants are
// stored in the RestaurantService.
type Restaurant struct {
	ID   int    `json:"-"`
	Name string `json:"name"`
}

// Restaurants is a slice of Restaurant pointers.
type Restaurants []*Restaurant
```

## The repository layer

The repository layer is responsible for connecting directly to the database to retrieve and/or modify records.

### The interface

```go
// OrderRepository is the interface that an order repository should conform to.
type OrderRepository interface {
	FindAllOrdersByUserID(userID int) (models.Orders, error)
}
```

We have defined only one method on the repository, `FindAllOrdersByUserID` which will return all orders made by a specific user.

### The default implementation

Since we are using [go-pg](https://github.com/go-pg/pg) along with the [Postgres](https://www.postgresql.org/) database, this is what the implementation looks like:

```go
// orderRepository is an implementation of an OrderRepository.
type orderRepository struct {
	db orm.DB
}

func (r *orderRepository) SetDB(db orm.DB) {
	r.db = db
}

func (r *orderRepository) getDB() orm.DB {
	if r.db != nil {
		return r.db
	}

	r.db = application.ResolveDB()
	return r.db
}

func (r *orderRepository) FindAllOrdersByUserID(userID int) (models.Orders, error) {
	orders := models.Orders{}
	err := r.getDB().Model(&orders).Where("user_id = ?", userID).Order("placed_at DESC").Select()
	return orders, err
}
```

### Testing the default implementation

The default implementation of the repository has to be tested while interacting with the database. This is to test that the correct information is being returned from the `FindAllOrdersByUserID` method. For writing test suites, I prefer using [Ginkgo](https://onsi.github.io/ginkgo/).

The test suite needs to cover some basic scenarios we might experience:

- When there are no orders for a user we expect to receive an empty slice of orders in return
- When there are orders for a user we expect to receive those orders in return

With that in mind, let's look at the test suite:

```go
var _ = Describe("OrderRespository", func() {
	var (
		tx        *pg.Tx
		orderRepo repositories.OrderRepository
		orders    models.Orders
		err       error

		userID = 5
	)

	BeforeEach(func() {
		tx, err = application.ResolveDB().Begin()
		Expect(err).To(BeNil())
		orderRepo = repositories.NewOrderRepository(tx)
	})

	Describe("FindAllOrdersByUserID", func() {
		Describe("with no records in the database", func() {
			It("returns an empty slice of orders", func() {
				orders, err = orderRepo.FindAllOrdersByUserID(userID)
				Expect(err).To(BeNil())
				Expect(len(orders)).To(Equal(0))
			})
		})

		Describe("when a few records exist", func() {
			BeforeEach(func() {
				order1 := &models.Order{
					Total:        1000,
					CurrencyCode: "GBP",
					UserID:       userID,
					RestaurantID: 8,
					PlacedAt:     time.Now().Add(-72 * time.Hour),
				}
				err = tx.Insert(order1)
				Expect(err).To(BeNil())

				order2 := &models.Order{
					Total:        2500,
					CurrencyCode: "GBP",
					UserID:       userID,
					RestaurantID: 9,
					PlacedAt:     time.Now().Add(-36 * time.Hour),
				}
				err = tx.Insert(order2)
				Expect(err).To(BeNil())

				order3 := &models.Order{
					Total:        600,
					CurrencyCode: "GBP",
					UserID:       7,
					RestaurantID: 8,
					PlacedAt:     time.Now().Add(-24 * time.Hour),
				}
				err = tx.Insert(order3)
				Expect(err).To(BeNil())
			})

			It("returns only the records belonging to the user, in order from latest palced_at first", func() {
				orders, err = orderRepo.FindAllOrdersByUserID(userID)
				Expect(err).To(BeNil())
				Expect(len(orders)).To(Equal(2))
				Expect(orders[0].RestaurantID).To(Equal(9))
				Expect(orders[1].RestaurantID).To(Equal(8))
			})
		})
	})

	AfterEach(func() {
		err = tx.Rollback()
		Expect(err).To(BeNil())
	})
})
```

At this point, the repository layer is tested and we can start to build on top of this foundation.

## External API clients

We only have one external API client, to make calls out to the `RestaurantService`.

### The interface

```go
// Client is an interface that describes a RestaurantService client.
type Client interface {
	GetRestaurantsByIDs(ids []int) (models.Restaurants, error)
}
```

### The default implementation

This is the `RestaurantService`'s HTTP client:

```go
// client is an implementation of a RestaurantService client interface.
type client struct {
	baseURL string
}

// SetBaseURL overrides the default base URL for the restaurants service.
func (c *client) SetBaseURL(url string) {
	c.baseURL = url
}

func (c *client) getBaseURL() string {
	if c.baseURL != "" {
		return c.baseURL
	}

	c.baseURL = os.Getenv("RESTAURANT_SERVICE_BASE_URL")
	return c.baseURL
}

// GetRestaurantsByIDs retrieves the Restaurants from the RestaurantService
// using a slice of integer IDs.
func (c *client) GetRestaurantsByIDs(ids []int) (models.Restaurants, error) {
	if len(ids) == 0 {
		return []*models.Restaurant{}, nil
	}

	idStrings := make([]string, 0, len(ids))
	for _, id := range ids {
		idStrings = append(idStrings, strconv.Itoa(id))
	}

	url := fmt.Sprintf(
		"%s/v1/restaurants?id=%s",
		c.getBaseURL(),
		strings.Join(idStrings, ","),
	)

	res, err := http.Get(url)
	if err != nil {
		return nil, err
	}

	if res.StatusCode != 200 {
		return nil, errors.New("error retrieving restaurants from RestaurantService")
	}

	body, err := ioutil.ReadAll(res.Body)
	if err != nil {
		return nil, err
	}

	parsedBody := models.Restaurants{}
	if err = json.Unmarshal(body, &parsedBody); err != nil {
		return nil, err
	}

	return parsedBody, nil
}
```

## Services

The services layer is responsible for the business logic of the application. The service layer will delegate reading and writing data to the repositories and external API clients, so that it can focus on the business logic.

### The interface

```go
// OrderService represents the business-logic layer for Orders in the system.
type OrderService interface {
	FindAllOrdersByUserID(userID int) (models.Orders, error)
}
```

This service will be responsible for retrieving the orders from the `OrderRepository`, augmenting the order data with the restaurant data by calling out to the restaurant API client, and then returning the result.

### The default implementation

```go
type orderService struct {
	db               orm.DB
	restaurantClient restaurant.Client
	orderRepository  repositories.OrderRepository
}

func (s *orderService) SetOrderRepository(r repositories.OrderRepository) {
	s.orderRepository = r
}

func (s *orderService) getOrderRepository() repositories.OrderRepository {
	if s.orderRepository != nil {
		return s.orderRepository
	}

	s.orderRepository = repositories.NewOrderRepository(application.ResolveDB())
	return s.orderRepository
}

func (s *orderService) SetRestaurantClient(c restaurant.Client) {
	s.restaurantClient = c
}

func (s *orderService) getRestaurantClient() restaurant.Client {
	if s.restaurantClient != nil {
		return s.restaurantClient
	}

	s.restaurantClient = restaurant.NewClient()
	return s.restaurantClient
}

func (s *orderService) FindAllOrdersByUserID(userID int) (models.Orders, error) {
	orders, err := s.getOrderRepository().FindAllOrdersByUserID(userID)
	if err != nil {
		return nil, err
	}

	if len(orders) == 0 {
		return orders, nil
	}

	restaurantIDs := make([]int, 0, len(orders))
	for _, order := range orders {
		restaurantIDs = append(restaurantIDs, order.RestaurantID)
	}

	restaurants, err := s.getRestaurantClient().GetRestaurantsByIDs(restaurantIDs)
	if err != nil {
		return nil, err
	}

	restaurantsByID := make(map[int]*models.Restaurant)
	for _, restaurant := range restaurants {
		restaurantsByID[restaurant.ID] = restaurant
	}

	for _, order := range orders {
		restaurant, ok := restaurantsByID[order.RestaurantID]
		if !ok {
			return nil, errors.Errorf("restaurant with ID %d not found", order.RestaurantID)
		}

		order.Restaurant = restaurant
	}

	return orders, nil
}
```

From the code we can see that the `orderService` calls out to the `FindAllOrdersByUserID` method of the `OrderRepository`, then calls out to the restaurant `Client` and combines the two results before returning the result to the caller.

### Testing the default implementation

At this point we need to start talking about how to generate mocks. My preferred mocking library is [golang/mock](https://github.com/golang/mock).

To generate a mock for the `OrderRepository`, we use the `mockgen` CLI as follows:

```
mockgen github.com/SebastianCoetzee/blog-order-service-example/repositories OrderRepository > mock_repositories/mock_order_repository.go
```

To generate a mock for the restaurant `Client`, we use the `mockgen` CLI as follows:

```
mockgen github.com/SebastianCoetzee/blog-order-service-example/clients/restaurant Client > clients/mock_restaurant/mock_client.go
```

The following scenarios need to be tested for the `orderService`:

- When there are no orders for a user, return an empty slice of orders
- When there are orders for a user, but the restaurant IDs can't be found by the restaurant client, return an error
- When there are orders for a user and the restaurant IDs can be found by the restaurant client, return a slice of orders with their restaurant information populated

This is what the test suite looks like:

```go
var _ = Describe("OrderService", func() {
	var (
		restaurantClient restaurant.Client
		orderRepo        repositories.OrderRepository
		orderService     services.OrderService
		orders           models.Orders
		ctrl             *gomock.Controller
		err              error

		userID = 5
	)

	BeforeEach(func() {
		ctrl = gomock.NewController(GinkgoT())
	})

	JustBeforeEach(func() {
		orderServiceImpl := services.NewOrderService()
		orderServiceImpl.SetOrderRepository(orderRepo)
		orderServiceImpl.SetRestaurantClient(restaurantClient)
		orderService = orderServiceImpl
	})

	Describe("FindAllOrdersByUserID", func() {
		Describe("with no records in the database", func() {
			BeforeEach(func() {
				orderRepoMock := mock_repositories.NewMockOrderRepository(ctrl)
				orderRepoMock.EXPECT().FindAllOrdersByUserID(gomock.Eq(userID))
				orderRepo = orderRepoMock
			})

			It("returns an empty slice of orders", func() {
				orders, err = orderService.FindAllOrdersByUserID(userID)
				Expect(err).To(BeNil())
				Expect(len(orders)).To(Equal(0))
			})
		})

		Describe("when a few records exist", func() {
			BeforeEach(func() {
				order1 := &models.Order{
					Total:        1000,
					CurrencyCode: "GBP",
					UserID:       userID,
					RestaurantID: 8,
					PlacedAt:     time.Now().Add(-72 * time.Hour),
				}
				order2 := &models.Order{
					Total:        2500,
					CurrencyCode: "GBP",
					UserID:       userID,
					RestaurantID: 9,
					PlacedAt:     time.Now().Add(-36 * time.Hour),
				}

				orderRepoMock := mock_repositories.NewMockOrderRepository(ctrl)
				orderRepoMock.EXPECT().
					FindAllOrdersByUserID(gomock.Eq(userID)).
					Return(models.Orders{order2, order1}, error(nil))
				orderRepo = orderRepoMock
			})

			Describe("when not all Restaurants can be found", func() {
				BeforeEach(func() {
					restaurantClientMock := mock_restaurant.NewMockClient(ctrl)
					restaurantClientMock.EXPECT().
						GetRestaurantsByIDs(gomock.Eq([]int{9, 8})).
						Return(models.Restaurants{}, error(nil))
					restaurantClient = restaurantClientMock
				})

				It("returns only the records belonging to the user, in order from latest palced_at first", func() {
					orders, err = orderService.FindAllOrdersByUserID(userID)
					Expect(err).To(MatchError("restaurant with ID 9 not found"))
				})
			})

			Describe("when all Restaurants are found", func() {
				BeforeEach(func() {
					restaurant1 := &models.Restaurant{
						ID:   9,
						Name: "Nando's",
					}

					restaurant2 := &models.Restaurant{
						ID:   8,
						Name: "KFC",
					}

					restaurantClientMock := mock_restaurant.NewMockClient(ctrl)
					restaurantClientMock.EXPECT().
						GetRestaurantsByIDs(gomock.Eq([]int{9, 8})).
						Return(models.Restaurants{restaurant1, restaurant2}, error(nil))
					restaurantClient = restaurantClientMock
				})

				It("returns only the records belonging to the user, in order from latest palced_at first", func() {
					orders, err = orderService.FindAllOrdersByUserID(userID)
					Expect(err).To(BeNil())
					Expect(len(orders)).To(Equal(2))
					Expect(orders[0].Restaurant.Name).To(Equal("Nando's"))
					Expect(orders[0].Total).To(Equal(2500))
					Expect(orders[1].Restaurant.Name).To(Equal("KFC"))
					Expect(orders[1].Total).To(Equal(1000))
				})
			})
		})
	})

	AfterEach(func() {
		ctrl.Finish()
	})
})
```

Take particular note of how the `OrderRepository` and restaurant `Client` is mocked out in the tests. By depending on interfaces and not concrete implementations, we are able to mock out these dependencies in order to allow the code to be tested.

## Handlers

The handler layer is responsible for parsing a request, calling out the the relevant service and then returning a response to the caller.

### Generating an interface for the gin Context

Since the project is using [gin](https://github.com/gin-gonic/gin), we need to generate a `Context` interface so that we can mock out the `*gin.Context` in tests. This is done using the [ifacemaker](https://github.com/vburenin/ifacemaker) CLI:

```
ifacemaker -f vendor/github.com/gin-gonic/gin/context.go -s Context -i Context -p handlers > handlers/context.go
```

### The endpoint provider

In order to allow dependencies to be injected, we shall declare an endpoint `Provider` that will hold the dependencies required by the handlers. This is what the `Provider` looks like:

```go
// Provider is the endpoint provider that holds the dependencies for the
// endpoints.
type Provider struct {
	orderService services.OrderService
}

// SetOrderService sets the OrderService dependency on the Provider.
func (p *Provider) SetOrderService(s services.OrderService) {
	p.orderService = s
}

func (p *Provider) getOrderService() services.OrderService {
	if p.orderService != nil {
		return p.orderService
	}

	p.orderService = services.NewOrderService()
	return p.orderService
}
```

Notice how the `OrderService` is held as an attribute on the `Provider`. This is done so that the order service can be mocked out in a test.

The handler method is defined as follows:

```go
// FindOrdersForUser gets the orders for a user from the user's ID.
func FindOrdersForUser(c *gin.Context) {
	p := &Provider{}
	p.FindOrdersForUser(c)
}

// FindOrdersForUser is the provider method that gets the orders for a user from
// the user's ID.
func (p *Provider) FindOrdersForUser(c Context) {
	userID, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.Status(http.StatusBadRequest)
		return
	}

	orders, err := p.getOrderService().FindAllOrdersByUserID(userID)
	if err != nil {
		c.Status(http.StatusInternalServerError)
		return
	}

	c.JSON(http.StatusOK, orders)
}
```

Notice that the `FindOrdersForUser` accepts the generated `Context` interface and not the standard `*gin.Context`.

### Testing the handler

The following scenarios need to be tested for the `Provider`:

- When an invalid ID is given, the handler should return a 400
- When an error is returned from the `OrderService`, the handler should return a 500
- When orders are returned from the `OrderService`, the handler should return a 200 along with the serialised JSON

This is what the test suite looks like:

```go
var _ = Describe("FindOrdersForUser", func() {
	var (
		c            handlers.Context
		p            *handlers.Provider
		orderService services.OrderService
		ctrl         *gomock.Controller
	)

	BeforeEach(func() {
		ctrl = gomock.NewController(GinkgoT())
	})

	JustBeforeEach(func() {
		p = &handlers.Provider{}
		p.SetOrderService(orderService)
	})

	Describe("with an invalid ID", func() {
		BeforeEach(func() {
			mockContext := mock_handlers.NewMockContext(ctrl)
			mockContext.EXPECT().Param(gomock.Eq("id")).Return("invalid_id")
			mockContext.EXPECT().Status(gomock.Eq(400))
			c = mockContext
		})

		It("should return a 400", func() {
			p.FindOrdersForUser(c)
		})
	})

	Describe("with a valid ID", func() {
		Describe("when an error is returned from the OrderService", func() {
			BeforeEach(func() {
				mockContext := mock_handlers.NewMockContext(ctrl)
				mockContext.EXPECT().Param(gomock.Eq("id")).Return("5")
				mockContext.EXPECT().Status(gomock.Eq(500))
				c = mockContext

				mockOrderService := mock_services.NewMockOrderService(ctrl)
				mockOrderService.EXPECT().FindAllOrdersByUserID(gomock.Eq(5)).Return(nil, errors.New("some error"))
				orderService = mockOrderService
			})

			It("should return a 500", func() {
				p.FindOrdersForUser(c)
			})
		})

		Describe("when the OrderService returns an order", func() {
			BeforeEach(func() {
				orders := models.Orders{}
				orders = append(orders, &models.Order{
					ID: 5,
					Restaurant: &models.Restaurant{
						ID:   9,
						Name: "Nando's",
					},
				})

				mockContext := mock_handlers.NewMockContext(ctrl)
				mockContext.EXPECT().Param(gomock.Eq("id")).Return("5")
				mockContext.EXPECT().JSON(gomock.Eq(200), gomock.Eq(orders))
				c = mockContext

				mockOrderService := mock_services.NewMockOrderService(ctrl)
				mockOrderService.EXPECT().FindAllOrdersByUserID(gomock.Eq(5)).Return(orders, error(nil))
				orderService = mockOrderService
			})

			It("should return a 200 with the JSON response", func() {
				p.FindOrdersForUser(c)
			})
		})
	})

	AfterEach(func() {
		ctrl.Finish()
	})
})
```

## Conclusion

As software engineers, we should ensure that our software is well-tested in order to keep the quality bar as high as possible.

In order to write code that is testable, the software should be divided up into logical layers with a separation of concerns. The different layers should interact with each other through interfaces rather than through concrete implementations. Mocks can be generated using tools in order to speed up development.

By using a test suite, interfaces and mocks, we can ensure a high quality of our software by having good test coverage.
