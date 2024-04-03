﻿using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using CCOInsights.SubscriptionManager.Functions;
using CCOInsights.SubscriptionManager.Functions.Operations.PolicyDefinitions;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

namespace CCOInsights.SubscriptionManager.UnitTests;

public class PolicyDefinitionsUpdaterTests
{
    private readonly IPolicyDefinitionsUpdater _updater;
    private readonly Mock<IStorage> _storageMock;
    private readonly Mock<ILogger<PolicyDefinitionsUpdater>> _loggerMock;
    private readonly Mock<IPolicyDefinitionProvider> _providerMock;

    public PolicyDefinitionsUpdaterTests()
    {
        _storageMock = new Mock<IStorage>();
        _loggerMock = new Mock<ILogger<PolicyDefinitionsUpdater>>();
        _providerMock = new Mock<IPolicyDefinitionProvider>();
        _updater = new PolicyDefinitionsUpdater(_storageMock.Object, _loggerMock.Object, _providerMock.Object);
    }

    [Fact]
    public async Task PolicyDefinitionsUpdater_UpdateAsync_ShouldUpdate_IfValid()
    {
        var response = new PolicyDefinitionResponse { Id = "Id" };
        _providerMock.Setup(x => x.GetAsync(It.IsAny<string>(), It.IsAny<CancellationToken>())).ReturnsAsync(new List<PolicyDefinitionResponse> { response });

        var subscriptionTest = new TestSubscription();
        await _updater.UpdateAsync(Guid.Empty.ToString(), subscriptionTest, CancellationToken.None);

        _providerMock.Verify(x => x.GetAsync(It.Is<string>(x => x == subscriptionTest.SubscriptionId), CancellationToken.None));
        _storageMock.Verify(x => x.UpdateItemAsync(It.IsAny<string>(), It.IsAny<string>(), It.Is<PolicyDefinitions>(x => x.SubscriptionId == subscriptionTest.SubscriptionId && x.TenantId == subscriptionTest.Inner.TenantId), It.IsAny<CancellationToken>()), Times.Once);
    }
}