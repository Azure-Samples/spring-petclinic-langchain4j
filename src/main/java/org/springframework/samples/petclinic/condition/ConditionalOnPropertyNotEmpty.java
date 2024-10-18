package org.springframework.samples.petclinic.condition;

import org.springframework.context.annotation.Conditional;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

@Target({ ElementType.TYPE, ElementType.METHOD })
@Retention(RetentionPolicy.RUNTIME)
@Conditional(PropertySpecifiedAndNotEmptyCondition.class)
public @interface ConditionalOnPropertyNotEmpty {

	String value();

}
